$ErrorActionPreference = 'Continue'
$base = $env:N8N_API_URL.TrimEnd('/')
$hd = @{ "X-N8N-API-KEY" = $env:N8N_API_KEY }
$projN8N = "C:\Users\zarsa\Desktop\Work\Facebook_chatbot\PROJECTS_N8N"
$newId = "5EALg4K0DcjgjYCo"
$oldIds = @("kjQmOlnjPN0uwjS4", "8B1btKNRetjqVKE2")

# Map: local JSON file -> n8n workflow ID
$files = @(
    @{ file = "$projN8N/workflows/facebook/le_bosphore_facebook_chatbot_v2__8gL49rxDwuTFscmx.json"; wid = "8gL49rxDwuTFscmx"; wasActive = $true },
    @{ file = "$projN8N/workflows/whatsapp/whats_app_chatbot_v3__5R1op9sxUvmP5E3u.json"; wid = "5R1op9sxUvmP5E3u"; wasActive = $false },
    @{ file = "$projN8N/workflows/whatsapp/mysql/whats_app_chatbot_v3_mysql.json"; wid = "9K2MxD4AN2Pujobo"; wasActive = $true },
    @{ file = "$projN8N/workflows/habib/habib_new.json"; wid = "YrbREQ7pdP1CNQEP"; wasActive = $true }
)

foreach ($f in $files) {
    Write-Host "=== Processing $($f.wid) ==="
    
    if (-not (Test-Path $f.file)) {
        Write-Host "  FILE NOT FOUND: $($f.file)"
        continue
    }
    
    $json = Get-Content -Raw -Path $f.file -Encoding UTF8
    
    # Count occurrences
    $count1 = ($json -split 'kjQmOlnjPN0uwjS4').Count - 1
    $count2 = ($json -split '8B1btKNRetjqVKE2').Count - 1
    Write-Host "  Found kjQmOlnjPN0uwjS4: $count1 times, 8B1btKNRetjqVKE2: $count2 times"
    
    if ($count1 -eq 0 -and $count2 -eq 0) {
        Write-Host "  No references to update"
        continue
    }
    
    # Replace all occurrences
    $json2 = $json -replace 'kjQmOlnjPN0uwjS4', $newId -replace '8B1btKNRetjqVKE2', $newId
    
    # PUT to n8n API
    try {
        $resp = Invoke-RestMethod -Headers $hd -Uri "$base/api/v1/workflows/$($f.wid)" -Method PUT -ContentType "application/json" -Body $json2 -TimeoutSec 30
        Write-Host "  PUT OK"
    } catch {
        Write-Host "  PUT FAILED: $($_.Exception.Message)"
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            Write-Host "  Response: $($reader.ReadToEnd())"
        }
        continue
    }
    
    # Activate if it was active
    if ($f.wasActive) {
        try {
            Invoke-RestMethod -Headers $hd -Uri "$base/api/v1/workflows/$($f.wid)/activate" -Method POST -TimeoutSec 30 | Out-Null
            Write-Host "  Activated OK"
        } catch {
            Write-Host "  ACTIVATE FAILED: $($_.Exception.Message)"
        }
    }
}

Write-Host ""
Write-Host "=== DONE ==="
