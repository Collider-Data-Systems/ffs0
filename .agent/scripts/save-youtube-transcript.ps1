param(
    [Parameter(Mandatory = $true)]
    [string]$Url,

    [Parameter(Mandatory = $true)]
    [string]$Title,

    [Parameter(Mandatory = $true)]
    [string]$Channel,

    [Parameter(Mandatory = $false)]
    [string]$Language = "en",

    [Parameter(Mandatory = $false)]
    [double]$DurationSeconds = 0,

    [Parameter(Mandatory = $false)]
    [string]$TranscriptFile,

    [Parameter(Mandatory = $false)]
    [string]$Transcript,

    [Parameter(Mandatory = $false)]
    [string]$Summary = "",

    [Parameter(Mandatory = $false)]
    [string[]]$Keywords = @(),

    [Parameter(Mandatory = $false)]
    [string[]]$Claims = @(),

    [Parameter(Mandatory = $false)]
    [string]$Notes = "",

    [Parameter(Mandatory = $false)]
    [string]$OutputDir = ".\\.agent\\kb\\reference\\youtube\\entries"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Convert-ToSlug {
    param([string]$Value)

    $lower = $Value.ToLowerInvariant()
    $slug = $lower -replace "[^a-z0-9]+", "-"
    $slug = $slug.Trim("-")

    if ([string]::IsNullOrWhiteSpace($slug)) {
        return "video"
    }

    return $slug
}

if ([string]::IsNullOrWhiteSpace($Transcript)) {
    if (-not [string]::IsNullOrWhiteSpace($TranscriptFile)) {
        if (-not (Test-Path -LiteralPath $TranscriptFile)) {
            throw "Transcript file not found: $TranscriptFile"
        }
        $Transcript = Get-Content -LiteralPath $TranscriptFile -Raw
    }
}

if ([string]::IsNullOrWhiteSpace($Transcript)) {
    throw "Provide transcript text with -Transcript or -TranscriptFile."
}

$slug = Convert-ToSlug -Value $Title
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$id = "yt:$slug"
$fileName = "yt-$slug-$stamp.json"

if (-not (Test-Path -LiteralPath $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$entry = [ordered]@{
    id               = $id
    source_type      = "youtube"
    source_url       = $Url
    retrieved_at     = (Get-Date).ToUniversalTime().ToString("o")
    title            = $Title
    channel          = $Channel
    language         = $Language
    duration_seconds = $DurationSeconds
    summary          = $Summary
    keywords         = $Keywords
    claims           = $Claims
    transcript       = $Transcript
    notes            = $Notes
}

$outPath = Join-Path $OutputDir $fileName
$entry | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $outPath -Encoding UTF8
Write-Host "Saved:" $outPath
