param(
    [Parameter(Mandatory = $true)]
    [string]$Url,

    [Parameter(Mandatory = $false)]
    [string]$Summary = "youtube ingest",

    [Parameter(Mandatory = $false)]
    [string[]]$Keywords = @("youtube", "kb-ingest")
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
if (Get-Variable -Name PSNativeCommandUseErrorActionPreference -ErrorAction SilentlyContinue) {
    $PSNativeCommandUseErrorActionPreference = $false
}

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

function Resolve-YtDlpCommand {
    $repoPython = Join-Path $repoRoot ".venv\Scripts\python.exe"
    $candidates = @()

    if (Test-Path -LiteralPath $repoPython) {
        $candidates += ,@($repoPython, "-m", "yt_dlp")
    }

    $legacyYtDlp = "c:/Users/HP/FFS0_HPlaptop/.venv/Scripts/yt-dlp.exe"
    if (Test-Path -LiteralPath $legacyYtDlp) {
        $candidates += ,@($legacyYtDlp)
    }

    $pathYtDlp = Get-Command yt-dlp -ErrorAction SilentlyContinue
    if ($pathYtDlp) {
        $candidates += ,@($pathYtDlp.Source)
    }

    foreach ($candidate in $candidates) {
        try {
            & $candidate[0] @($candidate | Select-Object -Skip 1) --version *> $null
            if ($LASTEXITCODE -eq 0) {
                return $candidate
            }
        }
        catch {
        }
    }

    throw "yt-dlp is not available from the repo .venv or PATH."
}

function Invoke-YtDlp {
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )

    & $script:YtDlpCommand[0] @($script:YtDlpCommand | Select-Object -Skip 1) @Arguments
}

$script:YtDlpCommand = Resolve-YtDlpCommand
$tmp = "./.agent/dev/reference/youtube/tmp"

if (-not (Test-Path -LiteralPath $tmp)) {
    New-Item -ItemType Directory -Path $tmp -Force | Out-Null
}

$id = (Invoke-YtDlp --no-warnings --print "%(id)s" $Url 2>$null | Select-Object -First 1)
$title = (Invoke-YtDlp --no-warnings --print "%(title)s" $Url 2>$null | Select-Object -First 1)
$channel = (Invoke-YtDlp --no-warnings --print "%(uploader)s" $Url 2>$null | Select-Object -First 1)

$id = [string]($id | ForEach-Object { $_.ToString().Trim() })
$title = [string]($title | ForEach-Object { $_.ToString().Trim() })
$channel = [string]($channel | ForEach-Object { $_.ToString().Trim() })

if ([string]::IsNullOrWhiteSpace($id)) { $id = "unknown" }
if ([string]::IsNullOrWhiteSpace($title)) { $title = $Url }
if ([string]::IsNullOrWhiteSpace($channel)) { $channel = "unknown" }

$base = Join-Path $tmp ("ingest-" + $id)
Remove-Item "$base*" -Force -ErrorAction SilentlyContinue

Invoke-YtDlp --no-warnings --write-sub --sub-lang en --skip-download --output $base $Url *> $null
$vtt = Get-ChildItem "$base*.vtt" -ErrorAction SilentlyContinue | Select-Object -First 1

if (-not $vtt) {
    Invoke-YtDlp --no-warnings --write-auto-sub --sub-lang en --skip-download --output $base $Url *> $null
    $vtt = Get-ChildItem "$base*.vtt" -ErrorAction SilentlyContinue | Select-Object -First 1
}

if (-not $vtt) {
    [pscustomobject]@{
        status = "no-captions"
        url = $Url
        title = $title
        channel = $channel
        kb_entry_path = ""
        error = ""
        description = "No manual/auto English captions found with yt-dlp (retry)."
    } | ConvertTo-Json -Depth 4
    exit 0
}

$transcriptPath = Join-Path $tmp ("transcript-" + $id + ".txt")
$seen = New-Object System.Collections.Generic.HashSet[string]
$out = New-Object System.Collections.Generic.List[string]

foreach ($line in (Get-Content -LiteralPath $vtt.FullName)) {
    $s = [string]$line
    $s = $s.Trim()
    if ([string]::IsNullOrWhiteSpace($s)) { continue }
    if ($s.StartsWith("WEBVTT") -or $s.StartsWith("Kind:") -or $s.StartsWith("Language:")) { continue }
    if ($s.Contains("-->")) { continue }

    $s = [regex]::Replace($s, "<[^>]*>", "")
    $s = $s.Replace("&amp;", "&").Replace("&gt;", "> ").Replace("&lt;", "<").Trim()
    if ([string]::IsNullOrWhiteSpace($s)) { continue }

    if ($seen.Add($s)) {
        [void]$out.Add($s)
    }
}

$out -join "`n" | Set-Content -LiteralPath $transcriptPath -Encoding UTF8

$saveParams = @{
    Url = $Url
    Title = $title
    Channel = $channel
    Language = "en"
    TranscriptFile = $transcriptPath
    Summary = $Summary
    Keywords = $Keywords
}

$beforeLatest = Get-ChildItem "./.agent/dev/reference/youtube/entries" -Filter *.json -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1 -ExpandProperty FullName

$saveOut = (& ./.agent/dev/save-youtube-transcript.ps1 @saveParams 2>&1 | Out-String)

$savedPath = ""
foreach ($line in ($saveOut -split "`r?`n")) {
    if ($line -like "Saved:*") {
        $savedPath = $line.Substring(6).Trim()
        break
    }
}

if ([string]::IsNullOrWhiteSpace($savedPath)) {
    $afterLatest = Get-ChildItem "./.agent/dev/reference/youtube/entries" -Filter *.json -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 1 -ExpandProperty FullName

    if ($afterLatest -and $afterLatest -ne $beforeLatest) {
        $savedPath = $afterLatest
    }
}

if ($savedPath -and (Test-Path -LiteralPath $savedPath)) {
    $rel = [System.IO.Path]::GetRelativePath((Get-Location).Path, (Resolve-Path -LiteralPath $savedPath).Path)
    [pscustomobject]@{
        status = "ingested"
        url = $Url
        title = $title
        channel = $channel
        kb_entry_path = $rel
        error = ""
        description = "Transcript extracted and stored in KB entry."
    } | ConvertTo-Json -Depth 4
} else {
    [pscustomobject]@{
        status = "failed"
        url = $Url
        title = $title
        channel = $channel
        kb_entry_path = ""
        error = $saveOut.Trim()
        description = "Extraction/save error during retry."
    } | ConvertTo-Json -Depth 6
}
