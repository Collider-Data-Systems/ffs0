$sources = (Get-Content C:\Users\HP\FFS0_HPlaptop\ffs0-factory-super\.agent\kb\superset\sources.json | ConvertFrom-Json).entries

$baseDate = (Get-Date).Date.AddHours(10) # 10 AM today
$i = 0

foreach ($source in $sources) {
    if ($source.url -match "youtube|google|act-school|anthropic|openai") {
        $start = $baseDate.AddHours($i * 2) # Every 2 hours
        $end = $start.AddHours(1)
        
        $urn = "urn:moos:calendar_event:source-check-$($source.id.Split(':')[-1])"
        
        $body = @{
            type = "ADD"
            actor = "urn:moos:agent:vscode-ai"
            add = @{
                urn = $urn
                type_id = "calendar_event"
                stratum = "S2"
                payload = @{
                    summary = "Review Source: $($source.label)"
                    description = "Curation check for: $($source.url)
Notes: $($source.notes)"
                    start_time = $start.ToString("o")
                    end_time = $end.ToString("o")
                    status = "confirmed"
                    source_id = $source.id
                }
            }
        } | ConvertTo-Json -Depth 10

        try {
            Invoke-RestMethod -Method POST -Uri "http://localhost:8000/morphisms" -ContentType "application/json" -Body $body
            Write-Host "Hydrated: $($source.label)"
        } catch {
            Write-Host "Failed: $_"
        }
        $i++
    }
}
