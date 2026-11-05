param(
    [Parameter(Mandatory = $true)] [string]$ProbeFile,
    [Parameter(Mandatory = $true)] [string]$BaseUrl,
    [string]$TokenEnvName = "",
    [string]$TokenFile = "",
    [string]$OutFile = "",
    [int]$TimeoutSeconds = 30
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# api-probe.ps1 executes one deterministic API probe for bug reproduction and
# regression. The token is read from a token file or an environment variable,
# never printed, and masked in every evidence output.

function Get-FullPath([string]$Path) {
    if ([System.IO.Path]::IsPathRooted($Path)) { return [System.IO.Path]::GetFullPath($Path) }
    return [System.IO.Path]::GetFullPath((Join-Path (Get-Location).Path $Path))
}

function Hide-Secret([string]$Text) {
    if ($null -eq $Text) { return "" }
    $out = $Text
    if ($script:hasToken -and $script:token.Length -ge 8) { $out = $out.Replace($script:token, "***") }
    return $out
}

function Hide-SensitiveHeader([string]$Name, [string]$Value) {
    if ($Name -match '(?i)^(authorization|cookie|set-cookie|proxy-authorization)$') { return "${Name}: ***" }
    return "${Name}: $(Hide-Secret $Value)"
}

function Convert-ToDisplayValue($Value) {
    if ($null -eq $Value) { return "" }
    $display = ""
    if ($Value -is [System.Management.Automation.PSCustomObject] -or $Value -is [System.Array]) {
        $display = $Value | ConvertTo-Json -Depth 4 -Compress
    } else {
        $display = [string]$Value
    }
    if ($display.Length -gt 200) { $display = $display.Substring(0, 200) + "...(truncated)" }
    return Hide-Secret $display
}

# Returns a hashtable with Status: PRESENT | NULL | MISSING | EMPTY | EMPTY_ARRAY.
function Test-FieldPath($Root, [string]$FieldPath) {
    $current = $Root
    foreach ($segment in $FieldPath.Split('.')) {
        $name = $segment
        $indexes = @()
        $match = [regex]::Match($segment, '^(.*?)((\[\d+\])+)$')
        if ($match.Success) {
            $name = $match.Groups[1].Value
            foreach ($indexMatch in [regex]::Matches($match.Groups[2].Value, '\[(\d+)\]')) {
                $indexes += [int]$indexMatch.Groups[1].Value
            }
        }
        if ($name -ne "") {
            if ($null -eq $current) { return @{ Status = "MISSING" } }
            $property = $current.PSObject.Properties[$name]
            if ($null -eq $property) { return @{ Status = "MISSING" } }
            $current = $property.Value
        }
        foreach ($index in $indexes) {
            if ($null -eq $current -or -not ($current -is [System.Array])) { return @{ Status = "MISSING" } }
            if ($index -ge $current.Count) { return @{ Status = "MISSING" } }
            $current = $current[$index]
        }
    }
    if ($null -eq $current) { return @{ Status = "NULL" } }
    if ($current -is [string] -and $current.Length -eq 0) { return @{ Status = "EMPTY" } }
    if ($current -is [System.Array] -and $current.Count -eq 0) { return @{ Status = "EMPTY_ARRAY" } }
    return @{ Status = "PRESENT"; Value = $current }
}

$probePath = Get-FullPath $ProbeFile
if (-not (Test-Path -LiteralPath $probePath -PathType Leaf)) { throw "Probe file does not exist: $probePath" }
$probe = Get-Content -LiteralPath $probePath -Raw -Encoding UTF8 | ConvertFrom-Json

$envName = $TokenEnvName
if ([string]::IsNullOrWhiteSpace($envName) -and $probe.auth -and $probe.auth.token_env) { $envName = $probe.auth.token_env }
if ([string]::IsNullOrWhiteSpace($envName)) { $envName = "XUEGUO_API_TOKEN" }

$token = ""
if (-not [string]::IsNullOrWhiteSpace($TokenFile)) {
    $tokenPath = Get-FullPath $TokenFile
    if (-not (Test-Path -LiteralPath $tokenPath -PathType Leaf)) { throw "Token file does not exist: $tokenPath" }
    $token = (Get-Content -LiteralPath $tokenPath -TotalCount 1 -Encoding UTF8).Trim()
} else {
    $raw = [Environment]::GetEnvironmentVariable($envName)
    if (-not [string]::IsNullOrWhiteSpace($raw)) { $token = $raw.Trim() }
}
$hasToken = -not [string]::IsNullOrWhiteSpace($token)

$method = "GET"
if ($probe.request -and $probe.request.method) { $method = [string]$probe.request.method }
$method = $method.ToUpperInvariant()
if ($method -ne "GET" -and $method -ne "HEAD") {
    Write-Warning "Non-readonly probe method ${method}: make sure the human gate was approved before running."
}

$base = $BaseUrl.TrimEnd('/')
$path = "/"
if ($probe.request -and $probe.request.path) { $path = [string]$probe.request.path }
if (-not $path.StartsWith("/")) { $path = "/" + $path }

$queryPairs = @()
if ($probe.request -and $probe.request.query) {
    foreach ($property in $probe.request.query.PSObject.Properties) {
        $value = $property.Value
        if ($value -is [System.Management.Automation.PSCustomObject] -or $value -is [System.Array]) {
            $value = $value | ConvertTo-Json -Depth 10 -Compress
        }
        $queryPairs += ("$($property.Name)=" + [System.Uri]::EscapeDataString([string]$value))
    }
}
$authType = "bearer"
if ($probe.auth -and $probe.auth.type) { $authType = [string]$probe.auth.type }
if ($authType -eq "query" -and $hasToken) {
    $queryName = "token"
    if ($probe.auth.query_name) { $queryName = [string]$probe.auth.query_name }
    $queryPairs += ("$queryName=" + [System.Uri]::EscapeDataString($token))
}
$url = "$base$path"
if ($queryPairs.Count -gt 0) {
    $separator = "?"
    if ($url.Contains("?")) { $separator = "&" }
    $url = $url + $separator + ($queryPairs -join "&")
}

$headers = @{}
if ($probe.request -and $probe.request.headers) {
    foreach ($property in $probe.request.headers.PSObject.Properties) { $headers[$property.Name] = [string]$property.Value }
}
if ($hasToken) {
    if ($authType -eq "bearer") { $headers["Authorization"] = "Bearer $token" }
    elseif ($authType -eq "header") {
        $headerName = "Authorization"
        if ($probe.auth.header_name) { $headerName = [string]$probe.auth.header_name }
        $headers[$headerName] = $token
    }
}

$bodyBytes = $null
$bodyDisplay = ""
if ($probe.request -and $null -ne $probe.request.body) {
    $bodySource = $probe.request.body
    if ($bodySource -is [System.Management.Automation.PSCustomObject] -or $bodySource -is [System.Array]) {
        $bodyText = $bodySource | ConvertTo-Json -Depth 10 -Compress
    } else {
        $bodyText = [string]$bodySource
    }
    if (-not $headers.ContainsKey("Content-Type")) { $headers["Content-Type"] = "application/json" }
    $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($bodyText)
    $bodyDisplay = Hide-Secret $bodyText
}

$urlDisplay = Hide-Secret $url
$headerDisplay = @()
foreach ($key in $headers.Keys) { $headerDisplay += (Hide-SensitiveHeader $key $headers[$key]) }

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
$status = 0
$responseBody = ""
$responseHeaderLines = @()
$errorMessage = ""
$gotResponse = $false
try {
    if ($null -ne $bodyBytes) {
        $response = Invoke-WebRequest -Uri $url -Method $method -Headers $headers -Body $bodyBytes -TimeoutSec $TimeoutSeconds -UseBasicParsing
    } else {
        $response = Invoke-WebRequest -Uri $url -Method $method -Headers $headers -TimeoutSec $TimeoutSeconds -UseBasicParsing
    }
    $stopwatch.Stop()
    $gotResponse = $true
    $status = [int]$response.StatusCode
    $responseBody = [string]$response.Content
    foreach ($key in $response.Headers.Keys) { $responseHeaderLines += (Hide-SensitiveHeader $key ([string]$response.Headers[$key])) }
} catch {
    $stopwatch.Stop()
    $exception = $_.Exception
    if ($exception -is [System.Net.WebException] -and $null -ne $exception.Response) {
        $gotResponse = $true
        $httpResponse = $exception.Response
        $status = [int]$httpResponse.StatusCode
        try {
            $reader = New-Object System.IO.StreamReader($httpResponse.GetResponseStream(), [System.Text.Encoding]::UTF8)
            $responseBody = $reader.ReadToEnd()
            $reader.Close()
        } catch { $responseBody = "" }
        foreach ($key in $httpResponse.Headers.AllKeys) { $responseHeaderLines += (Hide-SensitiveHeader $key ([string]$httpResponse.Headers[$key])) }
    } else {
        $errorMessage = $exception.Message
    }
}

$parsed = $null
$parseError = ""
if (-not [string]::IsNullOrWhiteSpace($responseBody)) {
    try { $parsed = $responseBody | ConvertFrom-Json } catch { $parseError = "Response body is not valid JSON: $($_.Exception.Message)" }
}

$fieldLines = @()
$failedFields = 0
$warnFields = 0
$requiredFields = @()
if ($probe.required_fields) { $requiredFields = @($probe.required_fields) }
foreach ($field in $requiredFields) {
    $result = Test-FieldPath $parsed $field
    $line = ""
    switch ($result.Status) {
        "PRESENT" { $line = "PASS  $field = $(Convert-ToDisplayValue $result.Value)" }
        "NULL" { $line = "FAIL  $field = null"; $failedFields++ }
        "MISSING" { $line = "FAIL  $field is missing"; $failedFields++ }
        "EMPTY" { $line = "WARN  $field is an empty string"; $warnFields++ }
        "EMPTY_ARRAY" { $line = "WARN  $field is an empty array"; $warnFields++ }
        default { $line = "FAIL  $field check error"; $failedFields++ }
    }
    $fieldLines += $line
}

$maxChars = 4000
if ($probe.response_max_chars) { $maxChars = [int]$probe.response_max_chars }
$bodyDisplay2 = Hide-Secret $responseBody
if ($bodyDisplay2.Length -gt $maxChars) { $bodyDisplay2 = $bodyDisplay2.Substring(0, $maxChars) + "...(truncated)" }

$verdict = "API_PROBE_PASS"
if (-not $gotResponse) {
    $verdict = "API_PROBE_ERROR"
} elseif ($failedFields -gt 0) {
    $verdict = "API_PROBE_FAIL"
} elseif ($requiredFields.Count -gt 0 -and $parseError -ne "") {
    $verdict = "API_PROBE_FAIL"
} elseif ($status -ge 400) {
    $verdict = "API_PROBE_FAIL"
}

$tokenLine = "NOT_PROVIDED"
if ($hasToken) { $tokenLine = "PROVIDED (masked in evidence)" }

$evidence = @()
$evidence += "# API Probe Evidence"
$evidence += ""
$evidence += "- Probe file: $probePath"
$evidence += "- Executed at (UTC): $([DateTime]::UtcNow.ToString("o"))"
$evidence += "- Token: $tokenLine"
$evidence += ""
$evidence += "## Request"
$evidence += ""
$evidence += "- Method: $method"
$evidence += "- URL: $urlDisplay"
if ($headerDisplay.Count -gt 0) { $evidence += "- Headers:"; $headerDisplay | ForEach-Object { $evidence += "  - $_" } }
if ($bodyDisplay -ne "") { $evidence += "- Body: $bodyDisplay" }
$evidence += ""
$evidence += "## Response"
$evidence += ""
if ($gotResponse) {
    $evidence += "- Status: $status"
    $evidence += "- Duration ms: $($stopwatch.ElapsedMilliseconds)"
    if ($responseHeaderLines.Count -gt 0) { $evidence += "- Headers:"; $responseHeaderLines | ForEach-Object { $evidence += "  - $_" } }
    $evidence += "- Body (max $maxChars chars):"
    $evidence += ""
    $evidence += '```text'
    $evidence += $bodyDisplay2
    $evidence += '```'
} else {
    $evidence += "- No HTTP response received."
    $evidence += "- Duration ms: $($stopwatch.ElapsedMilliseconds)"
    $evidence += "- Error: $errorMessage"
}
if ($parseError -ne "") { $evidence += "- JSON parse error: $parseError" }
$evidence += ""
if ($requiredFields.Count -gt 0) {
    $evidence += "## Required field checks"
    $evidence += ""
    $fieldLines | ForEach-Object { $evidence += $_ }
    $evidence += ""
}
$evidence += "## Verdict"
$evidence += ""
$evidence += "$verdict (status: $status, fields failed: $failedFields, fields warned: $warnFields)"
$evidenceText = $evidence -join [Environment]::NewLine

if (-not [string]::IsNullOrWhiteSpace($OutFile)) {
    $outPath = Get-FullPath $OutFile
    $outParent = Split-Path -Parent $outPath
    if (-not (Test-Path -LiteralPath $outParent)) { New-Item -ItemType Directory -Force -Path $outParent | Out-Null }
    Set-Content -LiteralPath $outPath -Value $evidenceText -Encoding UTF8
    Write-Output "Evidence: $outPath"
} else {
    Write-Output $evidenceText
}
Write-Output "API Probe: $verdict"
if ($verdict -eq "API_PROBE_PASS") { exit 0 }
if ($verdict -eq "API_PROBE_ERROR") { exit 2 }
exit 1
