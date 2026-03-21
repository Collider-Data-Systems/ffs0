$r = Invoke-RestMethod 'http://localhost:8000/state'
$r.nodes.PSObject.Properties | Where-Object { $_.Name -like 'urn:moos:agent:*' } | ForEach-Object { Write-Host "Agent: $($_.Name)" }
