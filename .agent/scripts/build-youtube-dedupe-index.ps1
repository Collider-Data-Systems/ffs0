param(
    [string]$EntriesDir = ".\\.agent\\kb\\reference\\youtube\\entries",
    [string]$OutputPath = ".\\.agent\\kb\\reference\\youtube\\dedupe-index.json"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-TranscriptHash {
    param([string]$Transcript)

    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($Transcript)
        $hash = $sha.ComputeHash($bytes)
        return ([System.BitConverter]::ToString($hash).Replace("-", "").ToLowerInvariant())
    }
    finally {
        $sha.Dispose()
    }
}

if (-not (Test-Path -LiteralPath $EntriesDir)) {
    throw "Entries directory not found: $EntriesDir"
}

$files = Get-ChildItem -LiteralPath $EntriesDir -Filter *.json | Sort-Object Name
$groups = @{}
$errors = @()

foreach ($file in $files) {
    try {
        $doc = Get-Content -LiteralPath $file.FullName -Raw | ConvertFrom-Json

        $id = [string]$doc.id
        $url = [string]$doc.source_url
        $transcript = [string]$doc.transcript
        $hash = Get-TranscriptHash -Transcript $transcript

        $retrievedRaw = [string]$doc.retrieved_at
        $retrieved = [DateTime]::MinValue
        if (-not [string]::IsNullOrWhiteSpace($retrievedRaw)) {
            try {
                $retrieved = [DateTime]$retrievedRaw
            }
            catch {
                $retrieved = [DateTime]::MinValue
            }
        }

        $key = "$id|$url|$hash"
        if (-not $groups.ContainsKey($key)) {
            $groups[$key] = @()
        }

        $groups[$key] += [PSCustomObject]@{
            file_name      = $file.Name
            file_path      = $file.FullName
            id             = $id
            source_url     = $url
            title          = [string]$doc.title
            channel        = [string]$doc.channel
            retrieved_at   = $retrievedRaw
            retrieved_sort = $retrieved.ToString("o")
            summary        = [string]$doc.summary
            keywords       = @($doc.keywords)
            transcript_len = $transcript.Length
            transcript_sha = $hash
        }
    }
    catch {
        $errors += [PSCustomObject]@{
            file  = $file.FullName
            error = $_.Exception.Message
        }
    }
}

$groupList = @()
foreach ($entry in $groups.GetEnumerator()) {
    $items = @($entry.Value | Sort-Object retrieved_sort, file_name)
    if ($items.Count -eq 0) {
        continue
    }

    $canonical = $items[0]
    $aliases = @()
    if ($items.Count -gt 1) {
        $aliases = @($items[1..($items.Count - 1)])
    }

    $groupList += [PSCustomObject]@{
        id                      = $canonical.id
        source_url              = $canonical.source_url
        transcript_sha          = $canonical.transcript_sha
        transcript_len          = $canonical.transcript_len
        canonical_file_name     = $canonical.file_name
        canonical_file_path     = $canonical.file_path
        canonical_retrieved_at  = $canonical.retrieved_at
        canonical_summary       = $canonical.summary
        canonical_keywords      = $canonical.keywords
        alias_count             = $aliases.Count
        aliases                 = $aliases
    }
}

$duplicates = @($groupList | Where-Object { $_.alias_count -gt 0 } | Sort-Object id, canonical_retrieved_at)
$duplicateFileCount = 0
foreach ($dup in $duplicates) {
    $duplicateFileCount += [int]$dup.alias_count
}

$index = [PSCustomObject]@{
    generated_at              = (Get-Date).ToUniversalTime().ToString("o")
    entries_dir               = (Resolve-Path -LiteralPath $EntriesDir).Path
    total_files               = $files.Count
    unique_content_groups     = $groupList.Count
    groups_with_duplicates    = $duplicates.Count
    duplicate_file_count      = $duplicateFileCount
    groups                    = $groupList
    duplicate_groups          = $duplicates
    parse_errors              = $errors
}

$index | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $OutputPath -Encoding UTF8
Write-Host "Wrote dedupe index:" $OutputPath
Write-Host "Total files:" $files.Count
Write-Host "Unique groups:" $groupList.Count
Write-Host "Groups with duplicates:" $duplicates.Count
