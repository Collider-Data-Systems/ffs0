param(
    [Parameter(Mandatory = $true)]
    [string[]]$Urls,

    [Parameter(Mandatory = $false)]
    [string]$ListName = "youtube-list-1"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Set-Location "c:/Users/HP/FFS0_HPlaptop/ffs0-factory-super"

$ydlp = "c:/Users/HP/FFS0_HPlaptop/.venv/Scripts/yt-dlp.exe"
$listDir = "./.agent/kb/reference/youtube/lists"
$tmpDir = "./.agent/kb/reference/youtube/tmp"
$entriesDir = "./.agent/kb/reference/youtube/entries"

New-Item -ItemType Directory -Path $listDir -Force | Out-Null
New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null
New-Item -ItemType Directory -Path $entriesDir -Force | Out-Null

$results = @()

for ($i = 0; $i -lt $Urls.Count; $i++) {
    $n = $i + 1
    $url = $Urls[$i]
    $work = Join-Path $tmpDir ("$ListName-item-" + $n)
    New-Item -ItemType Directory -Path $work -Force | Out-Null

    $title = ""
    $channel = ""
    $status = "failed"
    $description = ""
    $entryPath = ""
    $errorText = ""

    try {
        $title = & $ydlp --no-warnings --print "%(title)s" $url 2>$null
        $channel = & $ydlp --no-warnings --print "%(uploader)s" $url 2>$null
        if ([string]::IsNullOrWhiteSpace($title)) { $title = "Unknown title" }
        if ([string]::IsNullOrWhiteSpace($channel)) { $channel = "Unknown channel" }

        Push-Location $work
        & $ydlp --no-warnings --write-sub --sub-lang en --skip-download --output "transcript" $url *> $null
        if (-not (Get-ChildItem *.vtt -ErrorAction SilentlyContinue)) {
            & $ydlp --no-warnings --write-auto-sub --sub-lang en --skip-download --output "transcript" $url *> $null
        }
        $vtt = Get-ChildItem *.vtt -ErrorAction SilentlyContinue | Select-Object -First 1
        Pop-Location

        if ($vtt) {
            $vttPath = Join-Path $work $vtt.Name
            $transcriptTxt = Join-Path $work "transcript.txt"

            $lines = Get-Content -Path $vttPath -ErrorAction Stop
            $seen = New-Object System.Collections.Generic.HashSet[string]
            $out = New-Object System.Collections.Generic.List[string]
            foreach ($line in $lines) {
                $s = $line.Trim()
                if ([string]::IsNullOrWhiteSpace($s)) { continue }
                if ($s.StartsWith("WEBVTT") -or $s.StartsWith("Kind:") -or $s.StartsWith("Language:")) { continue }
                if ($s -match "-->") { continue }
                $s = [regex]::Replace($s, "<[^>]*>", "")
                $s = $s.Replace("&amp;", "&").Replace("&gt;", ">").Replace("&lt;", "<").Trim()
                if (-not [string]::IsNullOrWhiteSpace($s) -and $seen.Add($s)) {
                    $out.Add($s)
                }
            }
            $out | Set-Content -Path $transcriptTxt -Encoding UTF8

            $before = @(
                Get-ChildItem $entriesDir -Filter *.json -ErrorAction SilentlyContinue |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -First 1 -ExpandProperty FullName
            )

            & ./.agent/scripts/save-youtube-transcript.ps1 -Url $url -Title $title -Channel $channel -Language "en" -TranscriptFile $transcriptTxt -Summary "$ListName item $n" -Keywords "youtube",$ListName,"kb-ingest" | Out-Null

            $latest = Get-ChildItem $entriesDir -Filter *.json -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending |
                Select-Object -First 1 -ExpandProperty FullName

            if ($latest -and ($before.Count -eq 0 -or $latest -ne $before[0])) {
                $entryPath = $latest.Replace((Resolve-Path ".").Path + "\\", "").Replace("\\", "/")
            }

            $status = "ingested"
            $description = "Transcript extracted and stored in KB entry."
        }
        else {
            $status = "no-captions"
            $description = "No manual/auto English captions found with yt-dlp."
        }
    }
    catch {
        $status = "failed"
        $description = "Extraction error."
        $errorText = $_.Exception.Message
    }

    $results += [ordered]@{
        number = $n
        url = $url
        status = $status
        title = $title
        channel = $channel
        description = $description
        kb_entry_path = $entryPath
        error = $errorText
    }
}

$ts = Get-Date -Format "yyyyMMdd-HHmmss"
$listPath = Join-Path $listDir ("$ListName-" + $ts + ".json")

$payload = [ordered]@{
    list_id = $ListName
    created_at = (Get-Date).ToUniversalTime().ToString("o")
    source = "user-provided"
    total = $results.Count
    items = $results
}

$payload | ConvertTo-Json -Depth 8 | Set-Content -Path $listPath -Encoding UTF8
Write-Output $listPath
