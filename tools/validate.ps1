$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$required = @(
    "VERSION",
    "README.md",
    "docs\framework-architecture.md",
    "docs\versioning-and-upgrades.md",
    "templates\requirements\current.yaml",
    "templates\requirements\change-request.md",
    "templates\tasks\task.yaml",
    "templates\bugs\verification-plan.yaml",
    "templates\releases\manifest.yaml",
    "templates\coordination\conflict.yaml",
    "tools\install.ps1",
    "tools\upgrade.ps1"
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
if ($version -ne '1.0.0') { $errors += "VERSION must be 1.0.0, actual: $version" }
if ($errors.Count -gt 0) { $errors | ForEach-Object { Write-Error $_ }; exit 1 }
Write-Output "PASS: Xueguo Framework 1.0.0"
