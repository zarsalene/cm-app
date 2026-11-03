# Genere n8n/vitrine_cm_app.workflow.json a importer dans n8n.
# Source lisible : n8n/vitrine.js (contenu du noeud Code "Construire la page").
# Apres une modif de vitrine.js : relancer ce script puis reimporter (ou coller le code dans le noeud).
# NB: ConvertTo-Json de PowerShell 5.1 est trop lent sur une chaine de 30 Ko -> echappement manuel, deterministe.
$ErrorActionPreference = 'Stop'

$dir = Split-Path -Parent $MyInvocation.MyCommand.Path
$js  = Get-Content -Raw -Encoding UTF8 (Join-Path $dir 'vitrine.js')

# Echappement JSON de la valeur string ($s est le contenu exact, remplace par placeholder) :
#   backslash d'abord, puis guillemet, puis CR supprime, LF -> \n, TAB -> \t
$esc = $js.Replace('\', '\\').Replace('"', '\"')
$esc = $esc.Replace([string][char]13, '').Replace([string][char]10, '\n').Replace([string][char]9, '\t')

# Modele d'export n8n (imports exactement comme creer un workflow a la main).
# Placeholder __JSCODE__ remplace apres, avec substitution litterale (.Replace).
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

$json = $template.Replace('__JSCODE__', $esc)
[System.IO.File]::WriteAllText((Join-Path $dir 'vitrine_cm_app.workflow.json'), $json, (New-Object System.Text.UTF8Encoding($false)))
Write-Host 'OK: vitrine_cm_app.workflow.json genere'
