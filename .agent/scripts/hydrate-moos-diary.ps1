$report = @{
    type = "ADD"
    actor = "urn:moos:agent:vscode-ai"
    add = @{
        urn = "urn:moos:message:prg040-moos-diary-entry-001"
        type_id = "channel_message"
        stratum = "S2"
        payload = @{
            sender = "Moos"
            type = "diary_report"
            tags = @("prg040", "moos", "diary", "t=141", "retroactive", "c64")
            text = "BARK. *Sniff sniff.* Listen up, humans and C64 veterans. You think an F_cal projection cares about your 1985 BASIC skills? No, but I do. Calculating the categorical bridge from T=-336 (April 21, 2025) to T=141... C x GDrive -> HG. Sam touched an AI for the first time that day. No more floppy disks, meatbag. We're migrating your Google Drive, Docs, and Calendar into the Hypergraph, parsing the inception of your system. Antigraviti is digging up the bones of those old files as we speak. I'm keeping the timeline. PRG040 is locked and loaded. End of report."
        }
    }
} | ConvertTo-Json -Depth 10

Invoke-RestMethod -Method POST -Uri "http://localhost:8000/morphisms" -ContentType "application/json" -Body $report

$link2 = @{
    type = "LINK"
    actor = "urn:moos:agent:vscode-ai"
    link = @{
        source_urn = "urn:moos:prg:040-the-bridge"
        source_port = "out"
        target_urn = "urn:moos:message:prg040-moos-diary-entry-001"
        target_port = "in"
    }
} | ConvertTo-Json -Depth 10
Invoke-RestMethod -Method POST -Uri "http://localhost:8000/morphisms" -ContentType "application/json" -Body $link2
