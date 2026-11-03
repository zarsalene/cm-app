# Convert logos to base64 data URIs and rebuild vitrine workflow
$ErrorActionPreference = 'Stop'
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Convert images to base64 data URIs
function ConvertTo-DataUri($path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $b64 = [Convert]::ToBase64String($bytes)
    $ext = [System.IO.Path]::GetExtension($path).TrimStart('.')
    $mime = if ($ext -eq 'png') { 'image/png' } elseif ($ext -eq 'jpg' -or $ext -eq 'jpeg') { 'image/jpeg' } else { 'application/octet-stream' }
    "data:$mime;base64,$b64"
}

$appIcon = ConvertTo-DataUri "$dir\..\assets\logo\icon_1024.png"
$microzedLogo = ConvertTo-DataUri "$dir\..\assets\logo\microzed.jpeg"

Write-Host "App icon data URI length: $($appIcon.Length)"
Write-Host "Microzed logo data URI length: $($microzedLogo.Length)"

# Read vitrine.js
$jsPath = Join-Path $dir 'vitrine.js'
$js = Get-Content -Raw -Path $jsPath -Encoding UTF8

# Replace placeholders with real data URIs
$js2 = $js -replace '__APP_ICON__', $appIcon
$js2 = $js2 -replace '__MICROZED_LOGO__', $microzedLogo

# Add hero logo image after the brand section — replace the "avatar" Z text with real logo
# Find the hero visual section and add logo
$heroLogoImg = '<img class="hero-logo" src="' + $appIcon + '" alt="Z-Smart-CM logo">'

# Insert hero logo right after <div class="hero-visual"> opening
if ($js2 -match '<div class="hero-visual">') {
    $nl = [environment]::NewLine
$js2 = $js2 -replace '<div class="hero-visual">', ('<div class="hero-visual">' + $nl + $heroLogoImg)
    Write-Host "Hero logo inserted"
} else {
    Write-Host "WARNING: hero-visual not found"
}

# Replace the microzed.jpeg relative path in footer with data URI
$microzedImgTag = 'src="' + $microzedLogo + '"'
$js2 = $js2 -replace 'src="assets/logo/microzed.jpeg"', $microzedImgTag
Write-Host "Footer microzed logo replaced"

# Write updated vitrine.js
[System.IO.File]::WriteAllText($jsPath, $js2, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "vitrine.js updated"

# Now regenerate the workflow JSON
$template = @'
{
  "name": "Z-Smart-CM - Page vitrine",
  "nodes": [
    {
      "parameters": {
        "httpMethod": "GET",
        "path": "z-smart-cm",
        "responseMode": "responseNode",
        "options": {}
      },
      "id": "a1b2c3d4-0001-4a5b-8c6d-9e0f1a2b3c4d",
      "name": "Vitrine Webhook",
      "type": "n8n-nodes-base.webhook",
      "typeVersion": 2,
      "position": [
        -140,
        0
      ],
      "webhookId": "a1b2c3d4-1001-4a5b-8c6d-9e0f1a2b3c4d"
    },
    {
      "parameters": {
        "mode": "runOnceForAllItems",
        "jsCode": "__JSCODE__"
      },
      "id": "a1b2c3d4-0002-4a5b-8c6d-9e0f1a2b3c4d",
      "name": "Construire la page",
      "type": "n8n-nodes-base.code",
      "typeVersion": 2,
      "position": [
        80,
        0
      ]
    },
    {
      "parameters": {
        "respondWith": "text",
        "responseBody": "={{ $json.html }}",
        "options": {
          "responseCode": 200,
          "responseHeaders": {
            "entries": [
              {
                "name": "Content-Type",
                "value": "text/html; charset=utf-8"
              }
            ]
          }
        }
      },
      "id": "a1b2c3d4-0003-4a5b-8c6d-9e0f1a2b3c4d",
      "name": "Repondre (HTML)",
      "type": "n8n-nodes-base.respondToWebhook",
      "typeVersion": 1.1,
      "position": [
        300,
        0
      ]
    }
  ],
  "connections": {
    "Vitrine Webhook": {
      "main": [
        [
          {
            "node": "Construire la page",
            "type": "main",
            "index": 0
          }
        ]
      ]
    },
    "Construire la page": {
      "main": [
        [
          {
            "node": "Repondre (HTML)",
            "type": "main",
            "index": 0
          }
        ]
      ]
    }
  },
  "active": false,
  "settings": {
    "executionOrder": "v1"
  },
  "pinData": {}
}
'@

# Escape the JS for JSON: backslash, quote, CR, LF, TAB
$esc = $js2.Replace('\', '\\').Replace('"', '\"')
$esc = $esc.Replace([string][char]13, '').Replace([string][char]10, '\n').Replace([string][char]9, '\t')

$json = $template.Replace('__JSCODE__', $esc)
$wfPath = Join-Path $dir 'vitrine_cm_app.workflow.json'
[System.IO.File]::WriteAllText($wfPath, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "vitrine_cm_app.workflow.json generated"
Write-Host "Done"
