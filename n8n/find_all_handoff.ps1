$ErrorActionPreference = 'Continue'
$base = $env:N8N_API_URL.TrimEnd('/')
$hd = @{ "X-N8N-API-KEY" = $env:N8N_API_KEY }

# Get ALL workflows (paginate)
$allWfs = @()
$cursor = ""
do {
    if ($cursor) {
        $uri = "$base/api/v1/workflows?limit=100&cursor=" + [uri]::EscapeDataString($cursor)
    } else {
        $uri = "$base/api/v1/workflows?limit=100"
    }
    $page = Invoke-RestMethod -Headers $hd -Uri $uri -Method GET -TimeoutSec 30
    $allWfs += $page.data
    $cursor = $page.nextCursor
} while ($cursor)

Write-Host "Total workflows: $($allWfs.Count)"

# Find executeWorkflow nodes referencing either handoff manager
$oldIds = @("kjQmOlnjPN0uwjS4", "8B1btKNRetjqVKE2")
$newId = "5EALg4K0DcjgjYCo"

$toUpdate = @()
foreach ($wf in $allWfs) {
    $nodes = $wf.nodes | Where-Object {
        $_.type -eq "n8n-nodes-base.executeWorkflow" -and
        $oldIds -contains $_.parameters.workflowId.value
    }
    if ($nodes.Count -gt 0) {
        $toUpdate += [pscustomobject]@{
            id = $wf.id
            name = $wf.name
            active = $wf.active
            nodes = ($nodes | ForEach-Object { "$($_.name) -> $($_.parameters.workflowId.value)" })
        }
    }
}

Write-Host ""
Write-Host "=== WORKFLOWS NEEDING UPDATE ==="
foreach ($u in $toUpdate) {
    Write-Host "  $($u.name) ($($u.id)) active=$($u.active)"
    foreach ($n in $u.nodes) { Write-Host "    $n" }
}
