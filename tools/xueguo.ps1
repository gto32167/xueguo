param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("new", "route", "next", "spec-ready", "check", "start", "verify", "finish", "status")]
    [string]$Command,
    [string]$TaskFile,
    [string]$TaskId,
    [string]$Title,
    [ValidateSet("L0", "L1", "L2", "L3")]
    [string]$ChangeLevel,
    [string]$ProjectRoot = "",
    [string]$FeatureRoot = "",
    [string]$BaseRef = "",
    [string]$RepositoryPath = "",
    [string[]]$MavenArgs = @(),
    [string]$Evidence = ""
)

$ErrorActionPreference = "Stop"

function Get-ProjectRoot {
    if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) { return [System.IO.Path]::GetFullPath($ProjectRoot) }
    $scriptParent = Split-Path -Parent $PSScriptRoot
    if ((Split-Path -Leaf $PSScriptRoot) -eq ".agent-workflow") { return [System.IO.Path]::GetFullPath($scriptParent) }
    return [System.IO.Path]::GetFullPath((Get-Location).Path)
}

function Resolve-TaskFile {
    if ([string]::IsNullOrWhiteSpace($TaskFile)) { throw "TaskFile is required." }
    if ([System.IO.Path]::IsPathRooted($TaskFile)) { return [System.IO.Path]::GetFullPath($TaskFile) }
    return [System.IO.Path]::GetFullPath((Join-Path (Get-ProjectRoot) $TaskFile))
}

function Get-YamlScalar([string]$Content, [string]$Key) {
    $match = [regex]::Match($Content, "(?m)^$([regex]::Escape($Key)):\s*(.*)$")
    if (-not $match.Success) { return $null }
    return $match.Groups[1].Value.Trim().Trim('"').Trim("'")
}

function Set-YamlScalar([string]$Content, [string]$Key, [string]$Value) {
    $escaped = $Value.Replace("`r", " ").Replace("`n", " ")
    $pattern = "(?m)^$([regex]::Escape($Key)):\s*.*$"
    $replacement = "${Key}: $escaped"
    if ($Content -notmatch $pattern) { return ($Content.TrimEnd() + "`r`n$replacement`r`n") }
    return [regex]::Replace($Content, $pattern, $replacement, 1)
}

function Set-TaskStatus([string]$Content, [string]$Status, [string]$NextAction) {
    $updated = Set-YamlScalar $Content "status" $Status
    $updated = Set-YamlScalar $updated "next_action" $NextAction
    return Set-YamlScalar $updated "updated_at" ([DateTime]::UtcNow.ToString("o"))
}

function Read-Task {
    $path = Resolve-TaskFile
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Task file does not exist: $path" }
    $content = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    return [PSCustomObject]@{
        Path = $path
        Content = $content
        TaskId = Get-YamlScalar $content "task_id"
        Title = Get-YamlScalar $content "title"
        ChangeLevel = Get-YamlScalar $content "change_level"
        Status = Get-YamlScalar $content "status"
        NextAction = Get-YamlScalar $content "next_action"
    }
}

function Write-Task([string]$Path, [string]$Content) { Set-Content -LiteralPath $Path -Value $Content -Encoding UTF8 }

function Escape-Yaml([string]$Value) { return $Value.Replace("`r", " ").Replace("`n", " ").Replace('"', '\"') }

function Test-HumanGateRequired([string]$Content) { return $Content -match '(?m)^\s+required:\s*true\s*$' }

function Get-NextAction([string]$Status) {
    switch ($Status) {
        "DRAFT" { return "Run route to classify and select the minimum workflow." }
        "ROUTED" { return "Create or update the Feature Spec, then run spec-ready." }
        "SPEC_READY" { return "Run check with FeatureRoot before implementation." }
        "ANALYZED" { return "Run start before changing business code." }
        "READY_TO_IMPLEMENT" { return "Run start before changing business code." }
        "IMPLEMENTING" { return "Run verify with evidence or explicit Maven arguments." }
        "VERIFIED" { return "Run finish to generate the delivery summary." }
        "FINISHED" { return "No further workflow action is required." }
        "NEEDS_HUMAN" { return "Record the human decision, then run route again." }
        "BLOCKED" { return "Resolve the blocking issue, then inspect status and route again." }
        default { return "Inspect the task state and choose an explicit next action." }
    }
}

function Invoke-FeatureCheck {
    $root = Get-ProjectRoot
    if ([string]::IsNullOrWhiteSpace($FeatureRoot)) { throw "FeatureRoot is required for L2/L3 checks." }
    $featurePath = if ([System.IO.Path]::IsPathRooted($FeatureRoot)) { [System.IO.Path]::GetFullPath($FeatureRoot) } else { [System.IO.Path]::GetFullPath((Join-Path $root $FeatureRoot)) }
    $checker = Join-Path $root ".cursor\skills\scripts\feature-check.ps1"
    if (-not (Test-Path -LiteralPath $checker -PathType Leaf)) {
        $frameworkChecker = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "..\java-spring\.cursor\skills\scripts\feature-check.ps1"))
        if (Test-Path -LiteralPath $frameworkChecker -PathType Leaf) { $checker = $frameworkChecker } else { throw "feature-check.ps1 was not found under $root\.cursor\skills\scripts." }
    }
    $args = @("-ExecutionPolicy", "Bypass", "-File", $checker, "-FeatureRoot", $featurePath)
    if (-not [string]::IsNullOrWhiteSpace($BaseRef)) { $args += @("-BaseRef", $BaseRef) }
    & powershell @args
    if ($LASTEXITCODE -ne 0) { throw "Feature check failed with exit code $LASTEXITCODE." }
}

function Invoke-MavenVerification {
    if ([string]::IsNullOrWhiteSpace($RepositoryPath)) { return $false }
    $repo = [System.IO.Path]::GetFullPath($RepositoryPath)
    if (-not (Test-Path -LiteralPath $repo -PathType Container)) { throw "RepositoryPath does not exist: $repo" }
    if ($MavenArgs.Count -eq 0) { throw "MavenArgs is required when RepositoryPath is supplied." }
    Push-Location $repo
    try {
        & mvn @MavenArgs
        if ($LASTEXITCODE -ne 0) { throw "Maven verification failed with exit code $LASTEXITCODE." }
    } finally { Pop-Location }
    return $true
}

function New-Task {
    if ([string]::IsNullOrWhiteSpace($TaskId) -or [string]::IsNullOrWhiteSpace($Title) -or [string]::IsNullOrWhiteSpace($ChangeLevel)) { throw "new requires TaskId, Title and ChangeLevel." }
    $id = $TaskId -replace '^TASK-', ''
    $taskIdValue = "TASK-$id"
    $path = if ([string]::IsNullOrWhiteSpace($TaskFile)) { Join-Path (Join-Path (Get-ProjectRoot) "tasks") "$taskIdValue.yaml" } else { Resolve-TaskFile }
    if (Test-Path -LiteralPath $path) { throw "Refusing to overwrite existing task: $path" }
    $parent = Split-Path -Parent $path
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    $retrospective = if ($ChangeLevel -in @("L2", "L3")) { "true" } else { "false" }
    $body = @"
schema_version: 2
task_id: $taskIdValue
title: "$(Escape-Yaml $Title)"
change_level: $ChangeLevel
requirement_id: N/A
requirement_version: N/A
status: DRAFT
owner: null
execution:
  executor: AI
  uncertainty: MEDIUM
  reason: "Workflow runner task"
  system_automation: []
  human_gate:
    required: false
    owner: null
    reason: null
repositories: []
scope_summary: ""
must_read: []
spec_refs: []
deliverable: ""
verification: ""
conflict_level: GREEN
dependencies: []
verification_levels: []
memory_inputs: []
retrospective_required: $retrospective
next_action: "Run route to classify and select the minimum workflow."
updated_at: "$([DateTime]::UtcNow.ToString("o"))"
"@
    Write-Task $path $body.TrimStart()
    Write-Output "Created task: $path"
}

function Route-Task {
    $task = Read-Task
    if ($task.ChangeLevel -notin @("L0", "L1", "L2", "L3")) { throw "Task change_level must be L0, L1, L2 or L3." }
    if ($task.Status -notin @("DRAFT", "ROUTED", "READY_TO_IMPLEMENT", "NEEDS_HUMAN", "BLOCKED")) { throw "Task cannot be routed from status $($task.Status)." }
    if ($task.ChangeLevel -eq "L3" -and (Test-HumanGateRequired $task.Content)) {
        Write-Task $task.Path (Set-TaskStatus $task.Content "NEEDS_HUMAN" (Get-NextAction "NEEDS_HUMAN"))
        Write-Output "Task $($task.TaskId) is blocked by a required human decision."
        return
    }
    $nextStatus = if ($task.ChangeLevel -in @("L0", "L1")) { "READY_TO_IMPLEMENT" } else { "ROUTED" }
    $content = Set-TaskStatus $task.Content $nextStatus (Get-NextAction $nextStatus)
    Write-Task $task.Path $content
    Write-Output "Task $($task.TaskId) routed as $($task.ChangeLevel): $nextStatus"
    Write-Output "Next: $(Get-NextAction $nextStatus)"
}

function Show-Status {
    $task = Read-Task
    Write-Output "Task: $($task.TaskId)"
    Write-Output "Title: $($task.Title)"
    Write-Output "Change level: $($task.ChangeLevel)"
    Write-Output "Status: $($task.Status)"
    Write-Output "Next: $(Get-NextAction $task.Status)"
}

function Start-Task {
    $task = Read-Task
    if ($task.Status -notin @("READY_TO_IMPLEMENT", "ANALYZED")) { throw "Task must be READY_TO_IMPLEMENT or ANALYZED before start; actual status: $($task.Status)" }
    if ($task.ChangeLevel -eq "L3" -and (Test-HumanGateRequired $task.Content)) { throw "L3 task cannot start while human_gate.required is true." }
    Write-Task $task.Path (Set-TaskStatus $task.Content "IMPLEMENTING" (Get-NextAction "IMPLEMENTING"))
    Write-Output "Task $($task.TaskId) is now IMPLEMENTING."
}

function Mark-SpecReady {
    $task = Read-Task
    if ($task.ChangeLevel -notin @("L2", "L3")) { throw "spec-ready is only required for L2/L3 tasks." }
    if ($task.Status -ne "ROUTED") { throw "Task must be ROUTED before spec-ready; actual status: $($task.Status)" }
    if ([string]::IsNullOrWhiteSpace($FeatureRoot)) { throw "FeatureRoot is required for spec-ready." }
    $root = Get-ProjectRoot
    $featurePath = if ([System.IO.Path]::IsPathRooted($FeatureRoot)) { [System.IO.Path]::GetFullPath($FeatureRoot) } else { [System.IO.Path]::GetFullPath((Join-Path $root $FeatureRoot)) }
    if (-not (Test-Path -LiteralPath $featurePath -PathType Container)) { throw "FeatureRoot does not exist: $featurePath" }
    foreach ($name in @("spec.md", "tasks.md", "verify.md")) {
        if (-not (Test-Path -LiteralPath (Join-Path $featurePath $name) -PathType Leaf)) { throw "Feature Spec is missing $name under $featurePath" }
    }
    Write-Task $task.Path (Set-TaskStatus $task.Content "SPEC_READY" (Get-NextAction "SPEC_READY"))
    Write-Output "Feature Spec files are present: $($task.TaskId) is SPEC_READY."
}

function Check-Task {
    $task = Read-Task
    if ($task.ChangeLevel -in @("L0", "L1")) {
        if ($task.Status -notin @("DRAFT", "ROUTED", "READY_TO_IMPLEMENT", "IMPLEMENTING")) { throw "L0/L1 check cannot run from status $($task.Status)." }
        Write-Task $task.Path (Set-TaskStatus $task.Content "READY_TO_IMPLEMENT" (Get-NextAction "READY_TO_IMPLEMENT"))
        Write-Output "L0/L1 check passed: full Feature Spec gate is not required."
        return
    }
    if ($task.Status -notin @("SPEC_READY", "IMPLEMENTING")) { throw "L2/L3 check requires SPEC_READY or IMPLEMENTING; actual status: $($task.Status)" }
    if ($task.ChangeLevel -eq "L3" -and (Test-HumanGateRequired $task.Content)) { throw "L3 check cannot continue while human_gate.required is true." }
    Invoke-FeatureCheck
    Write-Task $task.Path (Set-TaskStatus $task.Content "ANALYZED" (Get-NextAction "ANALYZED"))
    Write-Output "L2/L3 Feature check passed: task is ANALYZED."
}

function Verify-Task {
    $task = Read-Task
    if ($task.Status -notin @("IMPLEMENTING", "VERIFYING")) { throw "Task must be IMPLEMENTING or VERIFYING before verify; actual status: $($task.Status)" }
    Write-Task $task.Path (Set-TaskStatus $task.Content "VERIFYING" (Get-NextAction "IMPLEMENTING"))
    $ranMaven = Invoke-MavenVerification
    if (-not $ranMaven) {
        if ([string]::IsNullOrWhiteSpace($Evidence)) { throw "Provide Evidence or RepositoryPath with MavenArgs for verification." }
        $evidencePath = if ([System.IO.Path]::IsPathRooted($Evidence)) { $Evidence } else { Join-Path (Get-ProjectRoot) $Evidence }
        if (-not (Test-Path -LiteralPath $evidencePath)) { throw "Evidence file does not exist: $evidencePath" }
    }
    $verificationValue = if ($ranMaven) { "mvn $($MavenArgs -join ' ') passed" } else { $Evidence }
    $content = Set-YamlScalar $task.Content "verification" $verificationValue
    Write-Task $task.Path (Set-TaskStatus $content "VERIFIED" (Get-NextAction "VERIFIED"))
    Write-Output "Verification passed: $($task.TaskId) is VERIFIED."
}

function Finish-Task {
    $task = Read-Task
    if ($task.Status -ne "VERIFIED") { throw "Task must be VERIFIED before finish; actual status: $($task.Status)" }
    $statusDir = Join-Path (Get-ProjectRoot) "status"
    if (-not (Test-Path -LiteralPath $statusDir)) { New-Item -ItemType Directory -Force -Path $statusDir | Out-Null }
    $reportPath = Join-Path $statusDir "$($task.TaskId)-finish.md"
    $report = @"
# Finish: $($task.TaskId)

- Title: $($task.Title)
- Change level: $($task.ChangeLevel)
- Generated at: $([DateTime]::UtcNow.ToString("o"))

## Delivery gate

The workflow runner observed a VERIFIED task state. Review changed files and remaining risks before release.
"@
    Write-Task $reportPath $report.TrimStart()
    Write-Task $task.Path (Set-TaskStatus $task.Content "FINISHED" (Get-NextAction "FINISHED"))
    Write-Output "Task finished: $($task.TaskId)"
    Write-Output "Delivery report: $reportPath"
}

switch ($Command) {
    "new" { New-Task }
    "route" { Route-Task }
    "next" { Show-Status }
    "status" { Show-Status }
    "spec-ready" { Mark-SpecReady }
    "check" { Check-Task }
    "start" { Start-Task }
    "verify" { Verify-Task }
    "finish" { Finish-Task }
}
