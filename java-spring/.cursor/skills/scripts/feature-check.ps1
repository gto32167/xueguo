param(
    [Parameter(Mandatory = $true)] [string]$FeatureRoot,
    [string]$BaseRef = ""
)

$ErrorActionPreference = "Stop"
$root = [System.IO.Path]::GetFullPath($FeatureRoot)
if (-not (Test-Path -LiteralPath $root -PathType Container)) {
    throw "Feature directory does not exist: $root"
}

$critical = @()
$warnings = @()
$script:featureCritical = @()
function Read-FeatureFile([string]$Name) {
    $path = Join-Path $root $Name
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $script:featureCritical += "Missing feature file: $Name"
        return ""
    }
    return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

$spec = Read-FeatureFile "spec.md"
$tasks = Read-FeatureFile "tasks.md"
$verify = Read-FeatureFile "verify.md"
$critical += $script:featureCritical
$constitutionPath = [System.IO.Path]::GetFullPath((Join-Path $root "..\..\constitution.md"))
if (-not (Test-Path -LiteralPath $constitutionPath -PathType Leaf)) {
    $warnings += "Constitution file is unavailable: $constitutionPath"
} else {
    $constitution = Get-Content -LiteralPath $constitutionPath -Raw -Encoding UTF8
}

foreach ($heading in @("Problem Statement", "Success Metrics", "User Stories", "Acceptance Criteria", "Non-Goals", "Constraints")) {
    if ($spec -notmatch "(?im)^#{1,3}\s+$([regex]::Escape($heading))\s*$") {
        $critical += "Spec is missing required section: $heading"
    }
}

function Get-Ids([string]$Text, [string]$Prefix) {
    return [regex]::Matches($Text, "\b$Prefix-\d+\b") | ForEach-Object { $_.Value } | Sort-Object -Unique
}

function Get-RawIds([string]$Text, [string]$Prefix) {
    return [regex]::Matches($Text, "\b$Prefix-\d+\b") | ForEach-Object { $_.Value }
}

$acIds = @(Get-Ids $spec "AC")
$smIds = @(Get-Ids $spec "SM")
$duplicateAcIds = @(Get-RawIds $spec "AC" | Group-Object | Where-Object Count -gt 1 | Select-Object -ExpandProperty Name)
$duplicateSmIds = @(Get-RawIds $spec "SM" | Group-Object | Where-Object Count -gt 1 | Select-Object -ExpandProperty Name)
if ($acIds.Count -eq 0) { $critical += "Spec has no AC-xxx Acceptance Criteria IDs" }
if ($smIds.Count -eq 0) { $warnings += "Spec has no SM-xxx Success Metrics IDs" }
if ($duplicateAcIds.Count -gt 0) { $critical += "Duplicate Acceptance Criteria IDs: $($duplicateAcIds -join ', ')" }
if ($duplicateSmIds.Count -gt 0) { $critical += "Duplicate Success Metrics IDs: $($duplicateSmIds -join ', ')" }

if ($tasks -notmatch "(?im)spec_refs") { $critical += "tasks.md is missing spec_refs mapping" }
if ($tasks -notmatch "(?im)deliverable") { $critical += "tasks.md is missing deliverable mapping" }
if ($tasks -notmatch "(?im)verification") { $critical += "tasks.md is missing verification mapping" }
if ($verify -notmatch "(?im)Acceptance Criteria") { $critical += "verify.md is missing Acceptance Criteria mapping" }
if ($verify -notmatch "(?im)Constitution") { $critical += "verify.md is missing Constitution check" }

foreach ($id in $acIds + $smIds) {
    if ($tasks -notmatch [regex]::Escape($id)) { $critical += "$id is not referenced by tasks.md" }
    if ($verify -notmatch [regex]::Escape($id)) { $critical += "$id is not referenced by verify.md" }
}

if ([string]::IsNullOrWhiteSpace($BaseRef)) {
    $warnings += "BaseRef not supplied; code-to-Spec drift check was not run"
} else {
    $repoRoot = (& git -C $root -c core.safecrlf=false -c core.autocrlf=false rev-parse --show-toplevel 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repoRoot)) {
        $warnings += "Git repository unavailable; code-to-Spec drift check was not run"
    } else {
        $changed = @((& git -C $repoRoot -c core.safecrlf=false -c core.autocrlf=false diff --name-only $BaseRef 2>$null) + (& git -C $repoRoot -c core.safecrlf=false -c core.autocrlf=false diff --cached --name-only $BaseRef 2>$null)) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique
        $featureSlug = Split-Path -Leaf $root
        $featurePrefix = "docs/features/$featureSlug/"
        $codeChanged = @($changed | Where-Object { $_ -match '(?i)(\.java$|pom\.xml$|\.sql$|application.*\.ya?ml$)' })
        $specChanged = @($changed | Where-Object { $_ -like "$featurePrefix*" })
        if ($codeChanged.Count -gt 0 -and $specChanged.Count -eq 0) {
            $critical += "Code changed without a matching feature Spec update since $BaseRef"
        }
    }
}

$name = Split-Path -Leaf $root
Write-Output "Feature Analyze: $name"
Write-Output "CRITICAL: $($critical.Count)"
Write-Output "WARNING: $($warnings.Count)"
$critical | ForEach-Object { Write-Output "CRITICAL: $_" }
$warnings | ForEach-Object { Write-Output "WARNING: $_" }
if ($critical.Count -gt 0) {
    Write-Output "Verdict: FAIL"
    exit 1
}
Write-Output "Verdict: PASS"
