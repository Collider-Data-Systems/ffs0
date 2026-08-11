# Batch ingest: runs ingest-youtube-url.ps1 per URL, writes a ledger to dev/data/youtube/lists.
param(
    [Parameter(Mandatory = $true)]
    [string[]]$Urls,

    [Parameter(Mandatory = $false)]
    [string]$ListName = "youtube-list-1",

    [Parameter(Mandatory = $false)]
    [string]$Language = "en",

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "youtube-common.ps1")

New-Item -ItemType Directory -Path $script:ListsDir -Force | Out-Null

$results = @()

for ($i = 0; $i -lt $Urls.Count; $i++) {
    $n = $i + 1
    $url = $Urls[$i]
    Write-Host "[$n/$($Urls.Count)] $url"

    $item = [ordered]@{
        number        = $n
        url           = $url
        status        = "failed"
        title         = ""
        channel       = ""
        description   = ""
        kb_entry_path = ""
        error         = ""
    }

    try {
        $args = @{
            Url      = $url
            Summary  = "$ListName item $n"
            Keywords = @("youtube", $ListName, "kb-ingest")
            Language = $Language
        }
        if ($Force) { $args.Force = $true }

        $raw = & (Join-Path $PSScriptRoot "ingest-youtube-url.ps1") @args
        $r = ($raw | Out-String) | ConvertFrom-Json

        $item.status = $r.status
        $item.title = $r.title
        $item.channel = $r.channel
        $item.description = $r.description
        $item.kb_entry_path = $r.kb_entry_path
        $item.error = $r.error
    }
    catch {
        $item.description = "Extraction error."
        $item.error = $_.Exception.Message
    }

    $results += $item
}

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$listPath = Join-Path $script:ListsDir ("$ListName-" + $ts + ".json")

[ordered]@{
    list_id    = $ListName
    created_at = (Get-Date).ToUniversalTime().ToString("o")
    source     = "user-provided"
    total      = $results.Count
    items      = $results
} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $listPath -Encoding UTF8

Write-Output $listPath
