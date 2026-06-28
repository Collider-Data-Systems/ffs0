<#
.SYNOPSIS
  Keyless secrets bootstrap — fetch provider API keys from Google Secret Manager into the CURRENT
  process env via ADC. No key files on disk. Resolved #64 secrets architecture (T=239).

.DESCRIPTION
  Identity is keyless and per-device (revocable, nothing copied):
    - GitHub  -> OS keyring  (`gh auth login`)
    - GCP     -> ADC         (`gcloud auth login` + `gcloud auth application-default login`)
                 ADC alone covers all of Vertex (Gemini Flash + every project model), Secret
                 Manager, and the Calendar/Keep DWD path — NO api key needed for those.
  The only file-class secrets are provider API keys that have no OAuth form (e.g. an AI-Studio
  Gemini key) — and even those are optional if you call Gemini via Vertex (ADC). This script
  fetches whatever IS in Secret Manager and SKIPS what isn't, so a pure-Vertex / zero-secret
  fleet works unchanged. The per-machine `secrets/api_keys.env` becomes an offline-only fallback.

.EXAMPLE
  # dot-source at session start so it populates THIS shell's env:
  . dev\scripts\ops\Get-Secrets.ps1
#>
param(
  [string]$Project = "mailmind-ai-djbuw",
  [switch]$Quiet
)
$ErrorActionPreference = 'Stop'

# secret-name (in Secret Manager) -> env var to populate. Extend as you add providers.
# Missing secrets are skipped (use Vertex/ADC instead, or store the key once).
$map = [ordered]@{
  'gemini-api-key'    = 'GEMINI_API_KEY'
  'anthropic-api-key' = 'ANTHROPIC_API_KEY'
  'openai-api-key'    = 'OPENAI_API_KEY'
}

if (-not (Get-Command gcloud -ErrorAction SilentlyContinue)) {
  Write-Warning "gcloud not found. Install the Cloud SDK + run: gcloud auth login; gcloud auth application-default login"
  return
}
$adc = Join-Path $env:APPDATA 'gcloud\application_default_credentials.json'
if (-not (Test-Path $adc)) {
  Write-Warning "No ADC found ($adc). Run: gcloud auth application-default login  (keyless — no key file)."
}

$loaded = 0
foreach ($secret in $map.Keys) {
  $var = $map[$secret]
  $val = (& gcloud secrets versions access latest --secret=$secret --project=$Project 2>$null)
  if ($LASTEXITCODE -eq 0 -and $val) {
    [Environment]::SetEnvironmentVariable($var, ($val -join "`n").Trim(), 'Process')
    $loaded++
    if (-not $Quiet) { Write-Host "  $var  <- secret:$secret" -ForegroundColor Green }
  } elseif (-not $Quiet) {
    Write-Host "  $var  (skipped — no secret:$secret; use Vertex/ADC, or: gcloud secrets create $secret --data-file=-)" -ForegroundColor DarkGray
  }
}
if (-not $Quiet) {
  Write-Host "Keyless bootstrap done — $loaded key(s) from Secret Manager. GitHub=keyring, GCP/Vertex/Keep/Calendar=ADC. No key files on disk." -ForegroundColor Cyan
}
