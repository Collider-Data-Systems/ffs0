# Sync-ProjectBoard.ps1 — mo:os board (Collider-Data-Systems project #4) operator CLI.
# Phase-1 of moos-github-project-bridge (F direction + audit; NO HG rewrites — the
# affordance-map github_identity.sync_policy gates G-sync until board-row identity is reliable).
#
#   pwsh -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Sync-ProjectBoard.ps1                     # Audit (read-only)
#   pwsh -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Sync-ProjectBoard.ps1 -Mode Sweep         # dry-run sweep plan
#   pwsh -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Sync-ProjectBoard.ps1 -Mode Sweep -Apply  # execute sweep
#   pwsh -NoProfile -ExecutionPolicy Bypass -File dev\scripts\ops\Sync-ProjectBoard.ps1 -Mode Attach -Repo ffs0 -Number 112 -HgUrn urn:moos:session:sam.laptop-vscode-lead -AgentId AGENT-VSCODE-COPILOT-HP-LAPTOP -OwnerRole user -Category agent_session -Phase verify
[CmdletBinding()]
param(
    [ValidateSet('Audit', 'Attach', 'Sweep')]
    [string]$Mode = 'Audit',

    # Attach mode — any org repo (Audit/Sweep scan only $TrackedRepos)
    [string]$Repo,
    [int]$Number,
    [string]$HgUrn,
    [string]$AgentId,
    [string]$Phase,
    [string]$OwnerRole,
    [string]$Category,

    # Sweep mode: mutate only when set; default prints the plan
    [switch]$Apply
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$Org = 'Collider-Data-Systems'
$TrackedRepos = @('ffs0', 'moos-kernel', 'moos-router')

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) { throw 'gh CLI not found on PATH.' }

function Invoke-GhJson {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $output = & gh @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw "gh $($Arguments -join ' ') failed: $((@($output) -join "`n"))" }
    return (@($output) -join "`n")
}

function Read-JsonFile {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) { throw "Missing config: $Path" }
    return Get-Content -Raw $Path | ConvertFrom-Json
}

$Cache = Read-JsonFile (Join-Path $RepoRoot 'dev\reference\project-field-ids.json')
$ProjectId = $Cache.project_id

function Get-FieldId { param([Parameter(Mandatory)][string]$Name) $Cache.fields.$Name.id }
function Get-OptionId {
    param([Parameter(Mandatory)][string]$Field, [Parameter(Mandatory)][string]$Option)
    $id = $Cache.fields.$Field.options.$Option
    if (-not $id) { throw "Unknown option '$Option' for field '$Field' (cache: dev/runbooks/project-field-ids.json)" }
    return $id
}

function Get-BoardItems {
    # All items with id, content repo#number+state, Status, HG URN. Paginates.
    $items = @()
    $cursor = 'null'
    while ($true) {
        $q = @"
{ node(id: "$ProjectId") { ... on ProjectV2 { items(first: 100, after: $cursor) {
  pageInfo { hasNextPage endCursor }
  nodes { id
    content { ... on Issue { repository { name } number state } ... on PullRequest { repository { name } number state } }
    status: fieldValueByName(name: "Status") { ... on ProjectV2ItemFieldSingleSelectValue { name } }
    urn: fieldValueByName(name: "HG URN") { ... on ProjectV2ItemFieldTextValue { text } }
} } } } }
"@
        $page = (Invoke-GhJson @('api', 'graphql', '-f', "query=$q") | ConvertFrom-Json).data.node.items
        foreach ($n in $page.nodes) {
            $c = $n.content
            if ($null -eq $c -or $c.PSObject.Properties.Match('number').Count -eq 0) { continue } # draft
            $items += [pscustomobject]@{
                ItemId = $n.id
                Repo   = $c.repository.name
                Number = $c.number
                State  = $c.state
                Status = if ($n.status) { $n.status.name } else { $null }
                HgUrn  = if ($n.urn) { $n.urn.text } else { $null }
            }
        }
        if (-not $page.pageInfo.hasNextPage) { break }
        $cursor = '"' + $page.pageInfo.endCursor + '"'
    }
    return $items
}

function Get-OpenRepoItems {
    # Open issues + PRs across tracked repos as repo/number/type/title/nodeId.
    $open = @()
    foreach ($r in $TrackedRepos) {
        $issues = Invoke-GhJson @('issue', 'list', '-R', "$Org/$r", '--state', 'open', '--limit', '200', '--json', 'number,title') | ConvertFrom-Json
        foreach ($i in @($issues)) { $open += [pscustomobject]@{ Repo = $r; Number = $i.number; Type = 'issue'; Title = $i.title } }
        $prs = Invoke-GhJson @('pr', 'list', '-R', "$Org/$r", '--state', 'open', '--limit', '200', '--json', 'number,title') | ConvertFrom-Json
        foreach ($p in @($prs)) { $open += [pscustomobject]@{ Repo = $r; Number = $p.number; Type = 'pr'; Title = $p.title } }
    }
    return $open
}

function Get-ContentNodeId {
    param([Parameter(Mandatory)][string]$RepoName, [Parameter(Mandatory)][int]$Num)
    $issue = Invoke-GhJson @('api', "repos/$Org/$RepoName/issues/$Num") | ConvertFrom-Json
    if ($issue.PSObject.Properties.Name -contains 'pull_request') {
        return (Invoke-GhJson @('api', "repos/$Org/$RepoName/pulls/$Num") | ConvertFrom-Json).node_id
    }
    return $issue.node_id
}

function Add-BoardItem {
    param([Parameter(Mandatory)][string]$ContentNodeId)
    $q = "mutation { addProjectV2ItemById(input: {projectId: `"$ProjectId`", contentId: `"$ContentNodeId`"}) { item { id } } }"
    return (Invoke-GhJson @('api', 'graphql', '-f', "query=$q") | ConvertFrom-Json).data.addProjectV2ItemById.item.id
}

function Set-ItemField {
    param(
        [Parameter(Mandatory)][string]$ItemId,
        [Parameter(Mandatory)][string]$FieldName,
        [string]$Text,
        [string]$Option
    )
    $fid = Get-FieldId $FieldName
    $value = if ($Option) { "{singleSelectOptionId: `"$(Get-OptionId $FieldName $Option)`"}" } else { "{text: `"$Text`"}" }
    $q = "mutation { updateProjectV2ItemFieldValue(input: {projectId: `"$ProjectId`", itemId: `"$ItemId`", fieldId: `"$fid`", value: $value}) { projectV2Item { id } } }"
    Invoke-GhJson @('api', 'graphql', '-f', "query=$q") | Out-Null
}

function Write-Section { param([string]$Title) Write-Host "=== $Title ===" -ForegroundColor Cyan }

switch ($Mode) {

    'Audit' {
        Write-Section "Board audit — $Org project #$($Cache.project_number) ($(Get-Date -Format 'yyyy-MM-dd HH:mm'))"
        $board = @(Get-BoardItems)
        $open = @(Get-OpenRepoItems)

        $onBoard = @{}
        foreach ($b in $board) { $onBoard["$($b.Repo)#$($b.Number)"] = $b }

        $unattached = @($open | Where-Object { -not $onBoard.ContainsKey("$($_.Repo)#$($_.Number)") })
        $openOrphans = @($board | Where-Object { $_.State -eq 'OPEN' -and -not $_.HgUrn })
        $driftClosed = @($board | Where-Object { $_.State -in @('CLOSED', 'MERGED') -and $_.Status -ne 'Done' })
        $driftOpen = @($board | Where-Object { $_.State -eq 'OPEN' -and $_.Status -eq 'Done' })
        $inProgress = @($board | Where-Object { $_.Status -eq 'In Progress' })

        Write-Host "board items: $($board.Count) / open repo items: $($open.Count)" -ForegroundColor Gray
        if ($unattached.Count) {
            Write-Host "UNATTACHED open items (run -Mode Sweep):" -ForegroundColor Yellow
            $unattached | ForEach-Object { Write-Host "  $($_.Repo)#$($_.Number) [$($_.Type)] $($_.Title)" -ForegroundColor Yellow }
        } else { Write-Host 'unattached open items: none' -ForegroundColor Green }
        if ($openOrphans.Count) {
            Write-Host 'OPEN items missing HG URN (backfill via -Mode Attach):' -ForegroundColor Yellow
            $openOrphans | ForEach-Object { Write-Host "  $($_.Repo)#$($_.Number)" -ForegroundColor Yellow }
        } else { Write-Host 'open-item HG URN coverage: complete' -ForegroundColor Green }
        if ($driftClosed.Count) {
            Write-Host 'STATUS DRIFT — closed/merged but not Done:' -ForegroundColor Red
            $driftClosed | ForEach-Object { Write-Host "  $($_.Repo)#$($_.Number) status=$($_.Status)" -ForegroundColor Red }
        }
        if ($driftOpen.Count) {
            Write-Host 'STATUS DRIFT — open but marked Done:' -ForegroundColor Red
            $driftOpen | ForEach-Object { Write-Host "  $($_.Repo)#$($_.Number)" -ForegroundColor Red }
        }
        if (-not $driftClosed.Count -and -not $driftOpen.Count) { Write-Host 'status drift: none' -ForegroundColor Green }
        if ($inProgress.Count) {
            Write-Host 'In Progress:' -ForegroundColor Gray
            $inProgress | ForEach-Object { Write-Host "  $($_.Repo)#$($_.Number) urn=$($_.HgUrn)" -ForegroundColor Gray }
        }
    }

    'Attach' {
        if (-not $Repo -or -not $Number) { throw 'Attach mode requires -Repo and -Number.' }
        Write-Section "Attach $Org/$Repo#$Number to board"
        $nodeId = Get-ContentNodeId -RepoName $Repo -Num $Number
        $itemId = Add-BoardItem -ContentNodeId $nodeId   # idempotent: re-add returns the existing item (verified live T=247 against an already-attached card)
        Write-Host "item: $itemId" -ForegroundColor Gray
        if ($HgUrn)     { Set-ItemField -ItemId $itemId -FieldName 'HG URN' -Text $HgUrn;            Write-Host "  HG URN = $HgUrn" -ForegroundColor Green }
        if ($AgentId)   { Set-ItemField -ItemId $itemId -FieldName 'Agent ID' -Text $AgentId;        Write-Host "  Agent ID = $AgentId" -ForegroundColor Green }
        if ($Phase)     { Set-ItemField -ItemId $itemId -FieldName 'Phase' -Text $Phase;             Write-Host "  Phase = $Phase" -ForegroundColor Green }
        if ($OwnerRole) { Set-ItemField -ItemId $itemId -FieldName 'Owner Role' -Option $OwnerRole;  Write-Host "  Owner Role = $OwnerRole" -ForegroundColor Green }
        if ($Category)  { Set-ItemField -ItemId $itemId -FieldName 'Collider Category' -Option $Category; Write-Host "  Collider Category = $Category" -ForegroundColor Green }
        if (-not $HgUrn) { Write-Host '  WARNING: no -HgUrn — item stays a G-direction orphan until backfilled.' -ForegroundColor Yellow }
    }

    'Sweep' {
        Write-Section "F-direction sweep $(if ($Apply) { '(APPLY)' } else { '(dry-run — pass -Apply to execute)' })"
        $board = @(Get-BoardItems)
        $open = @(Get-OpenRepoItems)
        $onBoard = @{}
        foreach ($b in $board) { $onBoard["$($b.Repo)#$($b.Number)"] = $b }

        $planAttach = @($open | Where-Object { -not $onBoard.ContainsKey("$($_.Repo)#$($_.Number)") })
        $planDone = @($board | Where-Object { $_.State -in @('CLOSED', 'MERGED') -and $_.Status -ne 'Done' })

        if (-not $planAttach.Count -and -not $planDone.Count) { Write-Host 'nothing to do — board is in sync' -ForegroundColor Green; break }

        foreach ($p in $planAttach) {
            Write-Host "attach + Status=Todo: $($p.Repo)#$($p.Number) — $($p.Title)" -ForegroundColor Yellow
            if ($Apply) {
                $itemId = Add-BoardItem -ContentNodeId (Get-ContentNodeId -RepoName $p.Repo -Num $p.Number)
                Set-ItemField -ItemId $itemId -FieldName 'Status' -Option 'Todo'
                Write-Host '  done' -ForegroundColor Green
            }
        }
        foreach ($d in $planDone) {
            Write-Host "Status -> Done: $($d.Repo)#$($d.Number) (was $($d.Status))" -ForegroundColor Yellow
            if ($Apply) {
                Set-ItemField -ItemId $d.ItemId -FieldName 'Status' -Option 'Done'
                Write-Host '  done' -ForegroundColor Green
            }
        }
    }
}
