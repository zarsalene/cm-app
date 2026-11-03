$ErrorActionPreference = 'Continue'
$base = $env:N8N_API_URL.TrimEnd('/')
$key = $env:N8N_API_KEY
$hd = @{ "X-N8N-API-KEY" = $key }
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
    
    # Fetch raw JSON from server (preserve exact formatting)
    try {
        $resp = Invoke-WebRequest -Headers $hd -Uri "$base/api/v1/workflows/$wid" -Method GET -TimeoutSec 30 -UseBasicParsing
        $rawJson = $resp.Content
    } catch {
        Write-Host "  FETCH FAILED: $($_.Exception.Message)"
        continue
    }
    
    $count1 = ($rawJson -split 'kjQmOlnjPN0uwjS4').Count - 1
    $count2 = ($rawJson -split '8B1btKNRetjqVKE2').Count - 1
    Write-Host "  Found in raw JSON: kjQmOlnjPN0uwjS4=$count1, 8B1btKNRetjqVKE2=$count2"
    
    if ($count1 -eq 0 -and $count2 -eq 0) {
        Write-Host "  No references to update"
        continue
    }
    
    # Replace in raw JSON string
    $rawJson2 = $rawJson -replace 'kjQmOlnjPN0uwjS4', $newId -replace '8B1btKNRetjqVKE2', $newId
    
    # Save to temp file
    $tempFile = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tempFile, $rawJson2, (New-Object System.Text.UTF8Encoding($false)))
    
    # PUT using curl.exe
    $putUri = "$base/api/v1/workflows/$wid"
    $curlArgs = @("-s", "-w", "\nHTTP_CODE:%{http_code}\n", "-X", "PUT", "$putUri", "-H", "X-N8N-API-KEY: $key", "-H", "Content-Type: application/json", "--data-binary", "@$tempFile")
    $output = & curl.exe @curlArgs 2>&1
    $httpCode = [regex]::Match($output, 'HTTP_CODE:(\d+)').Groups[1].Value
    Write-Host "  PUT HTTP: $httpCode"
    
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    
    # Activate if it was active
    if ($w.wasActive) {
        $actUri = "$base/api/v1/workflows/$wid/activate"
        $actOutput = & curl.exe -s -w "\nHTTP_CODE:%{http_code}\n" -X "POST" "$actUri" -H "X-N8N-API-KEY: $key" 2>&1
        $actCode = [regex]::Match($actOutput, 'HTTP_CODE:(\d+)').Groups[1].Value
        Write-Host "  Activate HTTP: $actCode"
    }
}

Write-Host ""
Write-Host "=== DONE ==="
