Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $PSScriptRoot
$hooksPath = Join-Path $repoRoot ".githooks"

if (-not (Test-Path -LiteralPath $hooksPath)) {
    throw "Hooks path not found: $hooksPath"
}

Push-Location $repoRoot
try {
    git config core.hooksPath .githooks
    Write-Output "Configured git hooks path to .githooks"
    Write-Output "Current hooksPath: $(git config --get core.hooksPath)"
}
finally {
    Pop-Location
}
