$ErrorActionPreference = 'Continue'
$base = $env:N8N_API_URL.TrimEnd('/')
$key = $env:N8N_API_KEY
$projN8N = "C:\Users\zarsa\Desktop\Work\Facebook_chatbot\PROJECTS_N8N"
$newId = "5EALg4K0DcjgjYCo"

# Map: local JSON file -> n8n workflow ID
$files = @(
    @{ file = "$projN8N/workflows/facebook/le_bosphore_facebook_chatbot_v2__8gL49rxDwuTFscmx.json"; wid = "8gL49rxDwuTFscmx"; wasActive = $true },
    @{ file = "$projN8N/workflows/whatsapp/whats_app_chatbot_v3__5R1op9sxUvmP5E3u.json"; wid = "5R1op9sxUvmP5E3u"; wasActive = $false },
    @{ file = "$projN8N/workflows/habib/habib_new.json"; wid = "YrbREQ7pdP1CNQEP"; wasActive = $true }
)

# Check whatsapp/mysql/whats_app_chatbot_v3_mysql.json - we saw it has 0 references in local scan
# but n8n server showed it references 8B1btKNRetjqVKE2. Let me check the local file too.
$mysqlFile = "$projN8N/workflows/whatsapp/mysql/whats_app_chatbot_v3_mysql.json"
if (Test-Path $mysqlFile) {
    $content = Get-Content -Raw -Path $mysqlFile -Encoding UTF8
    $c1 = ($content -split 'kjQmOlnjPN0uwjS4').Count - 1
    $c2 = ($content -split '8B1btKNRetjqVKE2').Count - 1
    Write-Host "mysql file: kjQmOlnjPN0uwjS4=$c1, 8B1btKNRetjqVKE2=$c2"
    if ($c1 -gt 0 -or $c2 -gt 0) {
        $files += @{ file = $mysqlFile; wid = "9K2MxD4AN2Pujobo"; wasActive = $true }
    }
}

foreach ($f in $files) {
    Write-Host "=== Processing $($f.wid) ==="
    
    if (-not (Test-Path $f.file)) {
        Write-Host "  FILE NOT FOUND: $($f.file)"
        continue
    }
    
    $json = Get-Content -Raw -Path $f.file -Encoding UTF8
    
    $count1 = ($json -split 'kjQmOlnjPN0uwjS4').Count - 1
    $count2 = ($json -split '8B1btKNRetjqVKE2').Count - 1
    Write-Host "  Found kjQmOlnjPN0uwjS4: $count1 times, 8B1btKNRetjqVKE2: $count2 times"
    
    if ($count1 -eq 0 -and $count2 -eq 0) {
        Write-Host "  No references to update"
        continue
    }
    
    # Replace all occurrences
    $json2 = $json -replace 'kjQmOlnjPN0uwjS4', $newId -replace '8B1btKNRetjqVKE2', $newId
    
    # Save to temp file
    $tempFile = [System.IO.Path]::GetTempFileName()
    [System.IO.File]::WriteAllText($tempFile, $json2, (New-Object System.Text.UTF8Encoding($false)))
    
    # PUT to n8n API using curl.exe
    $putUri = "$base/api/v1/workflows/$($f.wid)"
    $curlArgs = @("-s", "-w", "\nHTTP_CODE:%{http_code}\n", "-X", "PUT", "$putUri", "-H", "X-N8N-API-KEY: $key", "-H", "Content-Type: application/json", "--data-binary", "@$tempFile")
    $output = & curl.exe @curlArgs 2>&1
    Write-Host "  Response: $output"
    
    Remove-Item $tempFile -Force -ErrorAction SilentlyContinue
    
    # Activate if it was active
    if ($f.wasActive) {
        $actUri = "$base/api/v1/workflows/$($f.wid)/activate"
        $actOutput = & curl.exe -s -w "\nHTTP_CODE:%{http_code}\n" -X "POST" "$actUri" -H "X-N8N-API-KEY: $key" 2>&1
        Write-Host "  Activate: $actOutput"
    }
}

Write-Host ""
Write-Host "=== DONE ==="
