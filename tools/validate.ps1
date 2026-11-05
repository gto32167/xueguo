$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$required = @(
    "VERSION",
    "LICENSE",
    "README.md",
    "docs\framework-architecture.md",
    "docs\context-management.md",
    "docs\change-risk-routing.md",
    "docs\dogfooding.md",
    "docs\versioning-and-upgrades.md",
    "templates\requirements\current.yaml",
    "templates\requirements\change-request.md",
    "templates\tasks\task.yaml",
    "templates\bugs\verification-plan.yaml",
    "templates\bugs\api-probe.json",
    "templates\releases\manifest.yaml",
    "templates\coordination\conflict.yaml",
    "templates\memory\knowledge-entry.yaml",
    "templates\memory\validation-recipe.md",
    "templates\retrospectives\task-retrospective.md",
    "templates\status\project-status.yaml",
    "templates\status\session-checkpoint.yaml",
    "templates\changes\lightweight-change.yaml",
    "java-spring\.cursor\rules\context-budget.mdc",
    "java-spring\.cursor\rules\change-risk-routing.mdc",
    "java-spring\.cursor\skills\change-route\SKILL.md",
    "java-spring\.cursor\skills\bug-probe\SKILL.md",
    "java-spring\.cursor\skills\feature-analyze\SKILL.md",
    "java-spring\.cursor\skills\scripts\feature-check.ps1",
    "java-spring\.cursor\skills\scripts\api-probe.ps1",
    "java-spring\docs\features\_template\spec.md",
    "java-spring\docs\features\_template\tasks.md",
    "java-spring\docs\features\_template\verify.md",
    "tools\install.ps1",
    "tools\upgrade.ps1",
    "tools\xueguo.ps1",
    "docs\workflow-runner.md",
    "docs\api-probe.md"
)
$errors = @()
foreach ($relative in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $root $relative))) { $errors += "Missing file: $relative" }
}
$textFiles = Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object { $_.Extension -in @('.md', '.mdc', '.yaml', '.yml', '.json', '.ps1') }
foreach ($file in $textFiles) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $tripleQuestionMark = "?" + "?" + "?"
    if ($content.Contains($tripleQuestionMark) -and $file.Name -ne 'validate.ps1') { $errors += "Found triple question mark: $($file.FullName)" }
    if ($content.Contains([char]0xfffd)) { $errors += "Found replacement character: $($file.FullName)" }
}
$version = (Get-Content -LiteralPath (Join-Path $root 'VERSION') -Raw -Encoding UTF8).Trim()
if ($version -ne '1.5.0') { $errors += "VERSION must be 1.5.0, actual: $version" }
$installContent = Get-Content -LiteralPath (Join-Path $root 'tools\install.ps1') -Raw -Encoding UTF8
if ($installContent -notmatch '(?m)^\s*rollover_threshold_tokens:\s*260000\s*$') { $errors += "Default rollover threshold must be 260000 tokens." }
if ($errors.Count -gt 0) { $errors | ForEach-Object { Write-Error $_ }; exit 1 }
Write-Output "PASS: Xueguo Framework 1.5.0"
