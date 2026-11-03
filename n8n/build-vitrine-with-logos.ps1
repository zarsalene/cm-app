# Convert logos to base64 data URIs and rebuild vitrine workflow (with downscaled icon)
$ErrorActionPreference = 'Stop'
$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
Add-Type -AssemblyName System.Drawing

function ConvertTo-DataUri($path) {
    $bytes = [System.IO.File]::ReadAllBytes($path)
    $b64 = [Convert]::ToBase64String($bytes)
    $ext = [System.IO.Path]::GetExtension($path).TrimStart('.')
    $mime = if ($ext -eq 'png') { 'image/png' } elseif ($ext -eq 'jpg' -or $ext -eq 'jpeg') { 'image/jpeg' } else { 'application/octet-stream' }
    "data:$mime;base64,$b64"
}

function ResizeAndDataUri($srcPath, $maxDim) {
    $img = [System.Drawing.Image]::FromFile($srcPath)
    $w = $img.Width
    $h = $img.Height
    if ($w -gt $maxDim -or $h -gt $maxDim) {
        if ($w -gt $h) {
            $newW = $maxDim
            $newH = [int]($h * $maxDim / $w)
        } else {
            $newH = $maxDim
            $newW = [int]($w * $maxDim / $h)
        }
        $bmp = New-Object System.Drawing.Bitmap($newW, $newH)
        $g = [System.Drawing.Graphics]::FromImage($bmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($img, 0, 0, $newW, $newH)
        $g.Dispose()
        $img.Dispose()
        $img = $bmp
    }
    $ms = New-Object System.IO.MemoryStream
    $ext = [System.IO.Path]::GetExtension($srcPath).ToLower()
    if ($ext -eq '.png') {
        $img.Save($ms, ([System.Drawing.Imaging.ImageFormat]::Png))
    } else {
        $img.Save($ms, ([System.Drawing.Imaging.ImageFormat]::Jpeg))
    }
    $bytes = $ms.ToArray()
    $img.Dispose()
    $ms.Dispose()
    $b64 = [Convert]::ToBase64String($bytes)
    $mime = if ($ext -eq '.png') { 'image/png' } else { 'image/jpeg' }
    "data:$mime;base64,$b64"
}

# App icon: downscale to 128px max (used at 34x34 nav, 84x84 hero, favicon)
$appIcon = ResizeAndDataUri "$dir\..\assets\logo\icon_1024.png" 128
# Microzed logo: already small (200x200, 4.6KB), keep as-is
$microzedLogo = ConvertTo-DataUri "$dir\..\assets\logo\microzed.jpeg"

Write-Host "App icon data URI length: $($appIcon.Length)"
Write-Host "Microzed logo data URI length: $($microzedLogo.Length)"

# Read vitrine.js
$jsPath = Join-Path $dir 'vitrine.js'
$js = Get-Content -Raw -Path $jsPath -Encoding UTF8

# Replace placeholders with real data URIs
$js2 = $js -replace '__APP_ICON__', $appIcon

$nl = [environment]::NewLine
$heroLogoImg = '<img class="hero-logo" src="' + $appIcon + '" alt="Z-Smart-CM logo">'
$js2 = $js2 -replace '<div class="hero-visual">', ('<div class="hero-visual">' + $nl + $heroLogoImg)

$microzedImgTag = 'src="' + $microzedLogo + '"'
$js2 = $js2 -replace 'src="assets/logo/microzed.jpeg"', $microzedImgTag

# Write updated vitrine.js
[System.IO.File]::WriteAllText($jsPath, $js2, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "vitrine.js updated"

# Regenerate workflow JSON
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

$esc = $js2.Replace('\', '\\').Replace('"', '\"')
$esc = $esc.Replace([string][char]13, '').Replace([string][char]10, '\n').Replace([string][char]9, '\t')

$json = $template.Replace('__JSCODE__', $esc)
$wfPath = Join-Path $dir 'vitrine_cm_app.workflow.json'
[System.IO.File]::WriteAllText($wfPath, $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host "vitrine_cm_app.workflow.json generated"
Write-Host "Done"
