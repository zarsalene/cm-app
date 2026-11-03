$ErrorActionPreference = 'Continue'
$base = $env:N8N_API_URL.TrimEnd('/')
$key = $env:N8N_API_KEY
$newWfId = "0YZTAUySWHVbScYb"  # vitrine workflow ID on n8n server

$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$wfPath = Join-Path $dir 'vitrine_cm_app.workflow.json'

# Read the generated workflow JSON
$wf = Get-Content -Raw -Path $wfPath -Encoding UTF8 | ConvertFrom-Json

# Build minimal PUT body
$body = @{
    name = $wf.name
    nodes = $wf.nodes
    connections = $wf.connections
    settings = @{ executionOrder = "v1" }
}

$tempFile = [System.IO.Path]::GetTempFileName()
$jsonBody = $body | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($tempFile, $jsonBody, (New-Object System.Text.UTF8Encoding($false)))

# PUT
$putUri = "$base/api/v1/workflows/$newWfId"
$curlArgs = @("-s", "-w", "\nHTTP_CODE:%{http_code}\n", "-X", "PUT", "$putUri", "-H", "X-N8N-API-KEY: $key", "-H", "Content-Type: application/json", "--data-binary", "@$tempFile")
$output = & curl.exe @curlArgs 2>&1
$httpCode = [regex]::Match($output, 'HTTP_CODE:(\d+)').Groups[1].Value
Write-Host "PUT HTTP: $httpCode"
if ($httpCode -ne '200') { Write-Host $output }

Remove-Item $tempFile -Force -ErrorAction SilentlyContinue

# Activate
$actUri = "$base/api/v1/workflows/$newWfId/activate"
$actOutput = & curl.exe -s -w "\nHTTP_CODE:%{http_code}\n" -X "POST" "$actUri" -H "X-N8N-API-KEY: $key" 2>&1
$actCode = [regex]::Match($actOutput, 'HTTP_CODE:(\d+)').Groups[1].Value
Write-Host "Activate HTTP: $actCode"

Write-Host ""
Write-Host "=== DONE ==="
