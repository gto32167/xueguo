param(
    [Parameter(Mandatory = $true)] [string]$Target,
    [switch]$Check,
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"
$frameworkRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $frameworkRoot "java-spring"
$targetRoot = [System.IO.Path]::GetFullPath($Target)
$configPath = Join-Path $targetRoot ".agent-workflow\config.yaml"
if (-not (Test-Path -LiteralPath $targetRoot -PathType Container)) { throw "Target project directory does not exist: $targetRoot" }
if (-not (Test-Path -LiteralPath $configPath)) { throw "Missing .agent-workflow/config.yaml. Run install.ps1 first." }

function Get-RelativeFiles([string]$Root) {
    if (-not (Test-Path -LiteralPath $Root)) { return @() }
    return Get-ChildItem -LiteralPath $Root -Recurse -File | ForEach-Object {
        $_.FullName.Substring($Root.Length).TrimStart('\')
    }
}

$adds = @()
$updates = @()
foreach ($category in @(".cursor\rules", ".cursor\skills")) {
    $sourceDir = Join-Path $sourceRoot $category
    $targetDir = Join-Path $targetRoot $category
    foreach ($relative in (Get-RelativeFiles $sourceDir)) {
        $source = Join-Path $sourceDir $relative
        $target = Join-Path $targetDir $relative
        if (-not (Test-Path -LiteralPath $target)) { $adds += "$category\$relative"; continue }
        $sourceHash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
        $targetHash = (Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash
        if ($sourceHash -ne $targetHash) { $updates += "$category\$relative" }
    }
}

$version = (Get-Content (Join-Path $frameworkRoot "VERSION") -Raw).Trim()
$configContent = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
$missingRolloverThreshold = -not ($configContent -match '(?m)^\s*rollover_threshold_tokens\s*:')
Write-Output "Framework version: $version"
Write-Output "New files: $($adds.Count)"
Write-Output "Changed files: $($updates.Count)"
$adds | ForEach-Object { Write-Output "ADD $_" }
$updates | ForEach-Object { Write-Output "UPDATE $_" }
if ($missingRolloverThreshold) {
    Write-Warning "Project config has no rollover_threshold_tokens setting. Add context_management.rollover_threshold_tokens: 260000 manually; config.yaml is project-owned and will not be overwritten."
}
if ($Check -or $WhatIf) { exit 0 }

foreach ($category in @(".cursor\rules", ".cursor\skills")) {
    $sourceDir = Join-Path $sourceRoot $category
    $targetDir = Join-Path $targetRoot $category
    if (-not (Test-Path -LiteralPath $targetDir)) { New-Item -ItemType Directory -Force -Path $targetDir | Out-Null }
    Copy-Item -Path (Join-Path $sourceDir "*") -Destination $targetDir -Recurse -Force
}
Write-Output "Framework files upgraded. Project config and project space were preserved."
