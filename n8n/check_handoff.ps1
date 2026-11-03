$ErrorActionPreference = 'Continue'
$base = $env:N8N_API_URL.TrimEnd('/')
$hd = @{ "X-N8N-API-KEY" = $env:N8N_API_KEY }
$targets = @(
    "8gL49rxDwuTFscmx",
    "f32N0iDTz5FEz38t",
    "9K2MxD4AN2Pujobo",
    "8B1btKNRetjqVKE2",
    "c6qAkQvk2EMu1bcL",
    "d0m2fN2c8IZaPEiP",
    "YrbREQ7pdP1CNQEP",
    "QGD9YacsH0X2kn2p",
    "4aQxxaKRNBTegeXv",
    "brhB7OYSK1JZlDZ2"
)

foreach ($wid in $targets) {
    try {
        $uri = "$base/api/v1/workflows/$wid"
        $wf = Invoke-RestMethod -Headers $hd -Uri $uri -Method GET -TimeoutSec 30
        $nodes = $wf.nodes | Where-Object {
            $_.type -eq "n8n-nodes-base.executeWorkflow" -and
            $_.parameters.workflowId.value -eq "kjQmOlnjPN0uwjS4"
        }
        if ($nodes.Count -gt 0) {
            Write-Host "FOUND in $($wf.name) ($wid): $($nodes.Count) node(s)"
            foreach ($n in $nodes) {
                Write-Host "  node: $($n.name) id: $($n.id)"
            }
        } else {
            Write-Host "OK: $($wf.name) ($wid) - no reference"
        }
    } catch {
        Write-Host "ERR $wid : $($_.Exception.Message)"
    }
}
