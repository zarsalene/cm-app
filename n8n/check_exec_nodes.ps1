$ErrorActionPreference = 'Continue'
$base = $env:N8N_API_URL.TrimEnd('/')
$hd = @{ "X-N8N-API-KEY" = $env:N8N_API_KEY }

# Check the key bot workflows for ANY executeWorkflow node
$targets = @(
    "8gL49rxDwuTFscmx",
    "f32N0iDTz5FEz38t",
    "9K2MxD4AN2Pujobo",
    "5R1op9sxUvmP5E3u",
    "YrbREQ7pdP1CNQEP"
)

foreach ($wid in $targets) {
    try {
        $uri = "$base/api/v1/workflows/$wid"
        $wf = Invoke-RestMethod -Headers $hd -Uri $uri -Method GET -TimeoutSec 30
        $execNodes = $wf.nodes | Where-Object { $_.type -eq "n8n-nodes-base.executeWorkflow" }
        Write-Host "=== $($wf.name) ($wid) ==="
        foreach ($n in $execNodes) {
            $wid2 = $n.parameters.workflowId.value
            $mode = $n.parameters.workflowId.mode
            Write-Host "  Execute node: $($n.name) -> workflowId=$wid2 mode=$mode"
        }
    } catch {
        Write-Host "ERR $wid : $($_.Exception.Message)"
    }
}
