$ErrorActionPreference = 'Continue'
$base = $env:N8N_API_URL.TrimEnd('/')
$key = $env:N8N_API_KEY
$newId = "5EALg4K0DcjgjYCo"

$workflows = @(
    @{ id = "8gL49rxDwuTFscmx"; name = "le bosphore facebook chatbot v2"; wasActive = $true },
    @{ id = "5R1op9sxUvmP5E3u";  name = "whats app chatbot v3";          wasActive = $false },
    @{ id = "9K2MxD4AN2Pujobo";name = "whats app chatbot v3 (MySQL)";   wasActive = $true },
    @{ id = "YrbREQ7pdP1CNQEP";name = "Habib chatbot";                  wasActive = $true }
)

foreach ($w in $workflows) {
    $wid = $w.id
    Write-Host "=== Processing $($w.name) ($wid) ==="
    
    try {
        $wf = Invoke-RestMethod -Headers @{ "X-N8N-API-KEY" = $key } -Uri "$base/api/v1/workflows/$wid" -Method GET -TimeoutSec 30
    } catch {
        Write-Host "  FETCH FAILED: $($_.Exception.Message)"
        continue
    }
    
    $found = $false
    foreach ($node in $wf.nodes) {
        if ($node.type -eq "n8n-nodes-base.executeWorkflow") {
            $oldVal = $node.parameters.workflowId.value
            if ($oldVal -eq "kjQmOlnjPN0uwjS4" -or $oldVal -eq "8B1btKNRetjqVKE2") {
                Write-Host "  Updating node '$($node.name)': $oldVal -> $newId"
                $node.parameters.workflowId.value = $newId
                $found = $true
            }
        }
    }
    
    if (-not $found) {
        Write-Host "  No executeWorkflow nodes referencing old handoff managers"
        continue
    }
    
    # Minimal PUT body - settings must NOT have additional properties
    $body = @{
        name = $wf.name
        nodes = $wf.nodes
        connections = $wf.connections
        settings = @{ executionOrder = "v1" }
    }
    
    $tempFile = [System.IO.Path]::GetTempFileName()
    $jsonBody = $body | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($tempFile, $jsonBody, (New-Object System.Text.UTF8Encoding($false)))
    
    $putUri = "$base/api/v1/workflows/$wid"
    $curlArgs = @("-s", "-w", "\nHTTP_CODE:%{http_code}\n", "-X", "PUT", "$putUri", "-H", "X-N8N-API-KEY: $key", "-H", "Content-Type: application/json", "--data-binary", "@$tempFile")
    $output = & curl.exe @curlArgs 2>&1
    $httpCode = [regex]::Match($output, 'HTTP_CODE:(\d+)').Groups[1].Value
    Write-Host "  PUT HTTP: $httpCode"
    
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    
    if ($w.wasActive) {
        $actUri = "$base/api/v1/workflows/$wid/activate"
        $actOutput = & curl.exe -s -w "\nHTTP_CODE:%{http_code}\n" -X "POST" "$actUri" -H "X-N8N-API-KEY: $key" 2>&1
        $actCode = [regex]::Match($actOutput, 'HTTP_CODE:(\d+)').Groups[1].Value
        Write-Host "  Activate HTTP: $actCode"
    }
}

Write-Host ""
Write-Host "=== DONE ==="
