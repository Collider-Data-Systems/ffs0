$r = Invoke-RestMethod 'http://localhost:8000/state'
$skills = $r.nodes.PSObject.Properties | Where-Object { $_.Value.type_id -eq 'system_tool' }
Write-Host "Total Skill Nodes: $($skills.Count)"
$skills | Select-Object -First 3 | ForEach-Object {
    Write-Host "Node: $($_.Name)"
    $_.Value | ConvertTo-Json -Depth 5
}
