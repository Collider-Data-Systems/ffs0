$start = (Get-Date).Date.AddHours(20)
$end = $start.AddHours(1)

$body = @{
    type = "ADD"
    actor = "urn:moos:agent:vscode-ai"
    add = @{
        urn = "urn:moos:calendar_event:source-check-youtube-system3"
        type_id = "calendar_event"
        stratum = "S2"
        payload = @{
            summary = "MoOS Media Channel: Review YouTube Source"
            description = "Curation check for: 'System 3 AI: No Humans Needed'
URL: https://www.youtube.com/watch?v=K4yLplNrY24"
            start_time = $start.ToString("o")
            end_time = $end.ToString("o")
            status = "confirmed"
            source_id = "urn:moos:source:youtube"
        }
    }
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Method POST -Uri "http://localhost:8000/morphisms" -ContentType "application/json" -Body $body
