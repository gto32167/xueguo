param(
    [Parameter(Mandatory = $true)] [string]$Target,
    [Parameter(Mandatory = $true)] [string]$ProjectId,
    [string]$ProjectSpace = "",
    [switch]$WhatIf
)

$ErrorActionPreference = "Stop"
$frameworkRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $frameworkRoot "java-spring"
$targetRoot = [System.IO.Path]::GetFullPath($Target)
if (-not (Test-Path -LiteralPath $targetRoot -PathType Container)) {
    throw "Target project directory does not exist: $targetRoot"
}
if ([string]::IsNullOrWhiteSpace($ProjectId)) { throw "ProjectId is required." }
if ([string]::IsNullOrWhiteSpace($ProjectSpace)) {
    $ProjectSpace = Join-Path (Split-Path -Parent $targetRoot) "xueguo-projects"
}
$projectSpaceRoot = [System.IO.Path]::GetFullPath($ProjectSpace)
$projectDir = Join-Path $projectSpaceRoot $ProjectId

function Ensure-Directory([string]$Path) {
    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Force -Path $Path | Out-Null
    }
}

$version = (Get-Content (Join-Path $frameworkRoot "VERSION") -Raw).Trim()
if ($WhatIf) {
    Write-Output "Framework version: $version"
    Write-Output "Target project: $targetRoot"
    Write-Output "Project space: $projectDir"
    exit 0
}

foreach ($category in @(".cursor\rules", ".cursor\skills")) {
    $source = Join-Path $sourceRoot $category
    $destination = Join-Path $targetRoot $category
    Ensure-Directory $destination
    Copy-Item -LiteralPath (Join-Path $source "*") -Destination $destination -Recurse -Force
}

$agentDir = Join-Path $targetRoot ".agent-workflow"
Ensure-Directory $agentDir
$configPath = Join-Path $agentDir "config.yaml"
if (-not (Test-Path -LiteralPath $configPath)) {
    $config = @"
framework:
  name: xueguo
  version: $version
project:
  id: $ProjectId
  name: $ProjectId
workspace:
  path: $projectSpaceRoot
  memory_mode: central
"@
    Set-Content -LiteralPath $configPath -Value $config.TrimStart() -Encoding UTF8
}

foreach ($directory in @("tasks", "requirements", "releases", "coordination", "environments")) {
    Ensure-Directory (Join-Path $projectDir $directory)
}
Set-Content -LiteralPath (Join-Path $agentDir "managed-files.txt") -Value @(".cursor/rules", ".cursor/skills") -Encoding UTF8
Write-Output "Framework installed: $targetRoot"
Write-Output "Project space prepared: $projectDir"
