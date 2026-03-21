$r = Invoke-RestMethod 'http://localhost:8000/state'
$r.nodes.PSObject.Properties.Name | Out-File C:\Users\HP\FFS0_HPlaptop\ffs0-factory-super\all_urns.txt
