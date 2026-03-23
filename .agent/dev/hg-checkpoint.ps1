param(
    [string]$KernelBaseUrl = "http://localhost:8000",
    [string]$Actor = "urn:moos:agent:antigraviti",
    [string]$SessionUrn = "urn:moos:session:20260322-antigraviti",
    [string]$PrgUrn = "urn:moos:prg:000-session-meta",
    [string]$CheckpointType = "procedural",
    [string]$Summary = "procedural checkpoint"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$h = Invoke-RestMethod "$KernelBaseUrl/healthz"
$ts = Get-Date -Format "yyyyMMddHHmmss"
$msgUrn = "urn:moos:message:${ts}-checkpoint"
$text = "checkpoint=$CheckpointType summary=$Summary status=$($h.status) nodes=$($h.nodes) wires=$($h.wires) log_depth=$($h.log_depth)"

$add = @{
    type  = "ADD"
    actor = $Actor
    add   = @{
        urn     = $msgUrn
        type_id = "channel_message"
        stratum = "S2"
        payload = @{
            sender = "CheckpointBot"
            type   = "checkpoint"
            tags   = @("checkpoint", "hg", "procedural", "calendar-projection")
            text   = $text
        }
    }
} | ConvertTo-Json -Depth 10
Invoke-RestMethod "$KernelBaseUrl/morphisms" -Method Post -ContentType "application/json" -Body $add | Out-Null

if (-not [string]::IsNullOrWhiteSpace($SessionUrn)) {
    $l1 = @{
        type  = "LINK"
        actor = $Actor
        link  = @{
            source_urn  = $SessionUrn
            source_port = "owns"
            target_urn  = $msgUrn
            target_port = "child"
        }
    } | ConvertTo-Json -Depth 10
    Invoke-RestMethod "$KernelBaseUrl/morphisms" -Method Post -ContentType "application/json" -Body $l1 | Out-Null
}

if (-not [string]::IsNullOrWhiteSpace($PrgUrn)) {
    $l2 = @{
        type  = "LINK"
        actor = $Actor
        link  = @{
            source_urn  = $msgUrn
            source_port = "out"
            target_urn  = $PrgUrn
            target_port = "in"
        }
    } | ConvertTo-Json -Depth 10
    Invoke-RestMethod "$KernelBaseUrl/morphisms" -Method Post -ContentType "application/json" -Body $l2 | Out-Null
}

Write-Output $msgUrn
