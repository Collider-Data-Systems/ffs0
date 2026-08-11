# Shared helpers for the YouTube ingest lane. Dot-source from the sibling scripts.
# Successor to the retired .agent/dev/*.ps1 trio (removed at d649b60) — see dev/data/youtube/README.md.

Set-StrictMode -Version Latest

$script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path
$script:EntriesDir = Join-Path $script:RepoRoot "dev\data\youtube\entries"
$script:ListsDir = Join-Path $script:RepoRoot "dev\data\youtube\lists"
$script:YtTmpDir = Join-Path $script:RepoRoot "tmp\youtube"

function Resolve-YtDlpCommand {
    $candidates = @()

    $repoPython = Join-Path $script:RepoRoot ".venv\Scripts\python.exe"
    if (Test-Path -LiteralPath $repoPython) {
        $candidates += ,@($repoPython, "-m", "yt_dlp")
    }

    $pathYtDlp = Get-Command yt-dlp -ErrorAction SilentlyContinue
    if ($pathYtDlp) {
        $candidates += ,@($pathYtDlp.Source)
    }

    foreach ($candidate in $candidates) {
        try {
            & $candidate[0] @($candidate | Select-Object -Skip 1) --version *> $null
            if ($LASTEXITCODE -eq 0) {
                return ,$candidate
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

    if (-not (Get-Variable -Name YtDlpCommand -Scope Script -ErrorAction SilentlyContinue)) {
        $script:YtDlpCommand = Resolve-YtDlpCommand
    }
    & $script:YtDlpCommand[0] @($script:YtDlpCommand | Select-Object -Skip 1) @Arguments
}

function Get-YtVideoMetadata {
    param([Parameter(Mandatory = $true)][string]$Url)

    # One process for all four fields; yt-dlp emits each --print on its own line.
    $lines = @(Invoke-YtDlp --no-warnings --print "%(id)s" --print "%(title)s" --print "%(uploader)s" --print "%(duration)s" $Url 2>$null)
    $lines = @($lines | ForEach-Object { [string]$_ })

    $duration = 0.0
    if ($lines.Count -ge 4) { [double]::TryParse($lines[3], [ref]$duration) | Out-Null }

    [pscustomobject]@{
        VideoId          = if ($lines.Count -ge 1 -and $lines[0].Trim()) { $lines[0].Trim() } else { "unknown" }
        Title            = if ($lines.Count -ge 2 -and $lines[1].Trim()) { $lines[1].Trim() } else { $Url }
        Channel          = if ($lines.Count -ge 3 -and $lines[2].Trim()) { $lines[2].Trim() } else { "unknown" }
        DurationSeconds  = $duration
    }
}

function Convert-VttToText {
    param([Parameter(Mandatory = $true)][string]$VttPath)

    # YouTube auto-caption VTT repeats lines across overlapping cues — dedupe preserving order.
    $seen = New-Object System.Collections.Generic.HashSet[string]
    $out = New-Object System.Collections.Generic.List[string]

    foreach ($line in (Get-Content -LiteralPath $VttPath)) {
        $s = ([string]$line).Trim()
        if ([string]::IsNullOrWhiteSpace($s)) { continue }
        if ($s.StartsWith("WEBVTT") -or $s.StartsWith("Kind:") -or $s.StartsWith("Language:")) { continue }
        if ($s.Contains("-->")) { continue }

        $s = [regex]::Replace($s, "<[^>]*>", "")
        $s = $s.Replace("&amp;", "&").Replace("&gt;", ">").Replace("&lt;", "<").Trim()
        if ([string]::IsNullOrWhiteSpace($s)) { continue }

        if ($seen.Add($s)) {
            [void]$out.Add($s)
        }
    }

    return ($out -join "`n")
}

function Get-YtCaptionVtt {
    param(
        [Parameter(Mandatory = $true)][string]$Url,
        [Parameter(Mandatory = $true)][string]$OutputBase,
        [string]$Language = "en"
    )

    Remove-Item "$OutputBase*" -Force -ErrorAction SilentlyContinue

    Invoke-YtDlp --no-warnings --write-sub --sub-lang $Language --skip-download --output $OutputBase $Url *> $null
    $vtt = Get-ChildItem "$OutputBase*.vtt" -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($vtt) { return $vtt }

    Invoke-YtDlp --no-warnings --write-auto-sub --sub-lang $Language --skip-download --output $OutputBase $Url *> $null
    Get-ChildItem "$OutputBase*.vtt" -ErrorAction SilentlyContinue | Select-Object -First 1
}

function Find-ExistingEntry {
    param(
        [Parameter(Mandatory = $true)][string]$VideoId,
        [string]$EntriesDir = $script:EntriesDir
    )

    # Match on the immutable video id inside source_url, not on the title slug.
    if (-not (Test-Path -LiteralPath $EntriesDir)) { return $null }
    foreach ($f in (Get-ChildItem $EntriesDir -Filter *.json -ErrorAction SilentlyContinue)) {
        $raw = Get-Content -LiteralPath $f.FullName -Raw
        if ($raw -match [regex]::Escape($VideoId)) {
            try {
                $entry = $raw | ConvertFrom-Json
                if ($entry.source_url -match ("[?&]v=" + [regex]::Escape($VideoId)) -or
                    $entry.source_url -match ("youtu\.be/" + [regex]::Escape($VideoId))) {
                    return $f.FullName
                }
            }
            catch {
            }
        }
    }
    return $null
}
