param(
    [string]$KernelBaseUrl = "http://localhost:8000",
    [string]$ActorUrn = "urn:moos:agent:vscode-ai",
    [string]$FromSessionUrn = "urn:moos:session:20260324-vscodeHPL",
    [string]$ToSessionUrn = "urn:moos:session:20260324-claude-code-pm",
    [Parameter(Mandatory = $true)][string]$PrgUrn,
    [Parameter(Mandatory = $true)][string]$PhaseId,
    [Parameter(Mandatory = $true)][string]$Subject,
    [Parameter(Mandatory = $true)][string]$Body,
    [string]$PrUrl = "",
    [string]$MergeSha = "",
    [string]$Branch = "",
    [string]$ValidationResult = "",
    [string]$DelegationTaskUrn = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-Morph([object]$Envelope) {
    $json = $Envelope | ConvertTo-Json -Depth 25 -Compress
    Invoke-RestMethod "$KernelBaseUrl/morphisms" -Method Post -ContentType "application/json" -Body $json | Out-Null
}

function Get-Node([string]$Urn) {
    Invoke-RestMethod "$KernelBaseUrl/state/nodes/$Urn"
}

$prg = Get-Node -Urn $PrgUrn
$payload = @{}
foreach ($p in $prg.payload.PSObject.Properties) {
    $payload[$p.Name] = $p.Value
}

$now = (Get-Date).ToUniversalTime().ToString("o")
$phaseFound = $false
foreach ($phase in $payload.phases) {
    if ($phase.id -eq $PhaseId) {
        $phase.status = "completed"
        if ($phase.PSObject.Properties.Name -contains "completed_at") {
            $phase.completed_at = $now
        }
        else {
            $phase | Add-Member -NotePropertyName completed_at -NotePropertyValue $now -Force
        }
        if (-not [string]::IsNullOrWhiteSpace($ValidationResult)) {
            if ($phase.PSObject.Properties.Name -contains "validation_result") {
                $phase.validation_result = $ValidationResult
            }
            else {
                $phase | Add-Member -NotePropertyName validation_result -NotePropertyValue $ValidationResult -Force
            }
        }
        $phaseFound = $true
        break
    }
}

if (-not $phaseFound) {
    throw "Phase '$PhaseId' not found on $PrgUrn"
}

$mutate = @{
    type = "MUTATE"
    actor = $ActorUrn
    mutate = @{
        urn = $PrgUrn
        expected_version = [int]$prg.version
        payload = $payload
    }
}
Invoke-Morph -Envelope $mutate

if (-not [string]::IsNullOrWhiteSpace($DelegationTaskUrn)) {
    $task = Get-Node -Urn $DelegationTaskUrn
    $taskPayload = @{}
    foreach ($p in $task.payload.PSObject.Properties) {
        $taskPayload[$p.Name] = $p.Value
    }
    $taskPayload.status = "completed"
    $taskPayload.completed_at = $now
    $taskMutate = @{
        type = "MUTATE"
        actor = $ActorUrn
        mutate = @{
            urn = $DelegationTaskUrn
            expected_version = [int]$task.version
            payload = $taskPayload
        }
    }
    Invoke-Morph -Envelope $taskMutate
}

$stamp = (Get-Date).ToUniversalTime().ToString("yyyyMMdd-HHmmssfff")
$msgUrn = "urn:moos:message:$stamp-merge-checkpoint"
$fullBody = $Body
if (-not [string]::IsNullOrWhiteSpace($PrUrl)) { $fullBody += "`nPR: $PrUrl" }
if (-not [string]::IsNullOrWhiteSpace($MergeSha)) { $fullBody += "`nMerge SHA: $MergeSha" }
if (-not [string]::IsNullOrWhiteSpace($Branch)) { $fullBody += "`nBranch: $Branch" }

$addMessage = @{
    type = "ADD"
    actor = $ActorUrn
    add = @{
        urn = $msgUrn
        type_id = "channel_message"
        stratum = "S2"
        payload = @{
            subject = $Subject
            body = $fullBody
            from = $FromSessionUrn
            to = $ToSessionUrn
            status = "completed"
            tags = @("checkpoint", "merge", "prg", $PhaseId)
        }
    }
}
Invoke-Morph -Envelope $addMessage

$link = @{
    type = "LINK"
    actor = $ActorUrn
    link = @{
        source_urn = $msgUrn
        source_port = "out"
        target_urn = $PrgUrn
        target_port = "in"
    }
}
Invoke-Morph -Envelope $link

Write-Output ("Checkpoint complete. message={0} prg={1} phase={2}" -f $msgUrn, $PrgUrn, $PhaseId)
