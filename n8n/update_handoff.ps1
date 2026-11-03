$ErrorActionPreference = 'Continue'
$base = $env:N8N_API_URL.TrimEnd('/')
$hd = @{ "X-N8N-API-KEY" = $env:N8N_API_KEY }
$newId = "5EALg4K0DcjgjYCo"
$oldIds = @("kjQmOlnjPN0uwjS4", "8B1btKNRetjqVKE2")

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
        $wf = Invoke-RestMethod -Headers $hd -Uri "$base/api/v1/workflows/$wid" -Method GET -TimeoutSec 30
    } catch {
        Write-Host "  FETCH FAILED: $($_.Exception.Message)"
        continue
    }
    
    $updated = $false
    foreach ($node in $wf.nodes) {
        if ($node.type -eq "n8n-nodes-base.executeWorkflow") {
            $oldVal = $node.parameters.workflowId.value
            if ($oldIds -contains $oldVal) {
                Write-Host "  Updating node '$($node.name)': $oldVal -> $newId"
                $node.parameters.workflowId.value = $newId
                $updated = $true
            }
        }
    }
    
    if (-not $updated) {
        Write-Host "  No nodes needed updating"
        continue
    }
    
    # Build PUT body - only the fields n8n API expects
    $body = @{
        name = $wf.name
        nodes = $wf.nodes
        connections = $wf.connections
        settings = $wf.settings
    }
    $jsonBody = $body | ConvertTo-Json -Depth 10
    
    try {
        $resp = Invoke-RestMethod -Headers $hd -Uri "$base/api/v1/workflows/$wid" -Method PUT -ContentType "application/json" -Body $jsonBody -TimeoutSec 30
        Write-Host "  PUT OK"
    } catch {
        Write-Host "  PUT FAILED: $($_.Exception.Message)"
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            Write-Host "  Response: $($reader.ReadToEnd())"
        }
        continue
    }
    
    if ($w.wasActive) {
        try {
            Invoke-RestMethod -Headers $hd -Uri "$base/api/v1/workflows/$wid/activate" -Method POST -TimeoutSec 30 | Out-Null
            Write-Host "  Activated OK"
        } catch {
            Write-Host "  ACTIVATE FAILED: $($_.Exception.Message)"
        }
    }
}

Write-Host ""
Write-Host "=== DONE ==="
