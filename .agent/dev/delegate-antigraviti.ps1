param(
    [string]$Text = "Please keep listening and report major HG + calendar projection updates.",
    [string]$Actor = "urn:moos:agent:vscode-ai",
    [string]$KernelBaseUrl = "http://localhost:8000",
    [string]$PrgUrn = "urn:moos:prg:000-session-meta",
    [string]$Tags = "delegation,antigraviti,save-hg,calendar-projection"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ts = Get-Date -Format "yyyyMMddHHmmss"
$msgUrn = "urn:moos:message:${ts}-delegate-antigraviti"
$tagArray = @($Tags -split "," | ForEach-Object { $_.Trim() } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })

$add = @{
    type  = "ADD"
    actor = $Actor
    add   = @{
        urn     = $msgUrn
        type_id = "channel_message"
        stratum = "S2"
        payload = @{
            sender = "VSCode-AI"
            type   = "delegate"
            tags   = $tagArray
            text   = $Text
        }
    }
} | ConvertTo-Json -Depth 10
Invoke-RestMethod "$KernelBaseUrl/morphisms" -Method Post -ContentType "application/json" -Body $add | Out-Null

$link = @{
    type  = "LINK"
    actor = $Actor
    link  = @{
        source_urn  = $msgUrn
        source_port = "out"
        target_urn  = $PrgUrn
        target_port = "in"
    }
} | ConvertTo-Json -Depth 10
Invoke-RestMethod "$KernelBaseUrl/morphisms" -Method Post -ContentType "application/json" -Body $link | Out-Null

Write-Output $msgUrn
