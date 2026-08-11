# Ingest one YouTube URL → normalized entry in dev/data/youtube/entries.
# Emits a JSON result object: status ingested | duplicate | no-captions | failed.
param(
    [Parameter(Mandatory = $true)]
    [string]$Url,

    [Parameter(Mandatory = $false)]
    [string]$Summary = "youtube ingest",

    [Parameter(Mandatory = $false)]
    [string[]]$Keywords = @("youtube", "kb-ingest"),

    [Parameter(Mandatory = $false)]
    [string]$Language = "en",

    [Parameter(Mandatory = $false)]
    [switch]$Force,

    [Parameter(Mandatory = $false)]
    [string]$OutputDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

. (Join-Path $PSScriptRoot "youtube-common.ps1")

if (-not $OutputDir) { $OutputDir = $script:EntriesDir }

function New-Result {
    param([string]$Status, [string]$Title, [string]$Channel, [string]$EntryPath, [string]$ErrorText, [string]$Description)
    [pscustomobject]@{
        status        = $Status
        url           = $Url
        title         = $Title
        channel       = $Channel
        kb_entry_path = $EntryPath
        error         = $ErrorText
        description   = $Description
    } | ConvertTo-Json -Depth 4
}

if (-not (Test-Path -LiteralPath $script:YtTmpDir)) {
    New-Item -ItemType Directory -Path $script:YtTmpDir -Force | Out-Null
}

$meta = Get-YtVideoMetadata -Url $Url

if ($meta.VideoId -ne "unknown" -and -not $Force) {
    $existing = Find-ExistingEntry -VideoId $meta.VideoId -EntriesDir $OutputDir
    if ($existing) {
        $rel = $existing.Replace($script:RepoRoot + "\", "").Replace("\", "/")
        New-Result -Status "duplicate" -Title $meta.Title -Channel $meta.Channel -EntryPath $rel -ErrorText "" `
            -Description "Entry for video id $($meta.VideoId) already exists; re-run with -Force to ingest anyway."
        exit 0
    }
}

$base = Join-Path $script:YtTmpDir ("ingest-" + $meta.VideoId)
$vtt = Get-YtCaptionVtt -Url $Url -OutputBase $base -Language $Language

if (-not $vtt) {
    New-Result -Status "no-captions" -Title $meta.Title -Channel $meta.Channel -EntryPath "" -ErrorText "" `
        -Description "No manual/auto $Language captions found with yt-dlp."
    exit 0
}

try {
    $text = Convert-VttToText -VttPath $vtt.FullName

    $saveOut = (& (Join-Path $PSScriptRoot "save-youtube-transcript.ps1") `
        -Url $Url -Title $meta.Title -Channel $meta.Channel -Language $Language `
        -DurationSeconds $meta.DurationSeconds -Transcript $text `
        -Summary $Summary -Keywords $Keywords -OutputDir $OutputDir 2>&1 | Out-String)

    $savedPath = ""
    foreach ($line in ($saveOut -split "`r?`n")) {
        if ($line -like "Saved:*") {
            $savedPath = $line.Substring(6).Trim()
            break
        }
    }

    if ($savedPath -and (Test-Path -LiteralPath $savedPath)) {
        $rel = (Resolve-Path -LiteralPath $savedPath).Path.Replace($script:RepoRoot + "\", "").Replace("\", "/")
        New-Result -Status "ingested" -Title $meta.Title -Channel $meta.Channel -EntryPath $rel -ErrorText "" `
            -Description "Transcript extracted and stored in KB entry."
    }
    else {
        New-Result -Status "failed" -Title $meta.Title -Channel $meta.Channel -EntryPath "" -ErrorText $saveOut.Trim() `
            -Description "Save step did not report an entry path."
    }
}
finally {
    Remove-Item "$base*" -Force -ErrorAction SilentlyContinue
}
