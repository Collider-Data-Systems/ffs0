# Start-ScratchKernel.ps1 — T2 (t274, rev-4 blocker B5)
#
# Boot a throwaway kernel SEEDED FROM A COPY of a live fold's log, so a staged
# program can be validated end-to-end before any sovereign POST. An empty-log
# scratch kernel is useless for this: staged LINKs target nodes that exist only
# on the sovereign folds, so referential integrity rejects everything (Guido's
# t274 review, point 1). Seeding from the target fold's log makes the scratch
# fold a byte-parity twin at boot.
#
# Ruled at t249/t250 in four notes ("gate-tested on throwaway :8899"), built at
# t274. First hand-run: the D1 UNLINK validation, 2026-08-02.
#
# Usage:
#   pwsh -File dev\scripts\ops\Start-ScratchKernel.ps1                      # seed from Z440 primary, :8899
#   pwsh -File dev\scripts\ops\Start-ScratchKernel.ps1 -SeedLogPath <path>  # seed from another fold's log copy
#   then:  Test-MoosFederation.ps1 -Mode PostProgram -Persona <p> -PayloadPath <file> -TargetUrl http://localhost:8899
#   stop:  Stop-Process -Id <printed pid>
#
# The scratch dir lives under $env:TEMP — NEVER inside a repo (B2 discipline:
# a fold-log copy in a public worktree is one `git add -A` from publication).

[CmdletBinding()]
param(
    [int]$Port = 8899,
    [int]$McpPort = 0,
    [string]$SeedLogPath = 'D:\HPZ440\moos-kernel\moos.jsonl',
    [string]$OntologyPath = '',
    [string]$KernelExe = 'D:\HPZ440\moos-kernel\moos-kernel.exe',
    [string]$ScratchRoot = ''
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
if (-not $OntologyPath) { $OntologyPath = Join-Path $RepoRoot 'kb\superset\ontology.json' }
if ($McpPort -eq 0) { $McpPort = $Port - 1 }
if (-not $ScratchRoot) { $ScratchRoot = Join-Path $env:TEMP ("moos-scratch-{0}" -f $Port) }

foreach ($required in @($SeedLogPath, $OntologyPath, $KernelExe)) {
    if (-not (Test-Path $required)) { throw "Missing: $required" }
}

# B2 guard: refuse a scratch root inside any git worktree — the seed is a copy
# of a sovereign log and must never become committable.
$gitProbe = git -C $ScratchRoot rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -eq 0 -and "$gitProbe".Trim() -eq 'true') {
    throw "ScratchRoot '$ScratchRoot' is inside a git worktree — refuse (B2: sovereign-log copies never live where git can see them)."
}

# Refuse a busy port instead of stacking kernels.
try {
    $null = Invoke-RestMethod -Uri ("http://localhost:{0}/healthz" -f $Port) -TimeoutSec 2
    throw "Port $Port already serves a kernel — stop it first or pick another -Port."
} catch [System.Net.Http.HttpRequestException] { }
catch { if ($_.Exception.Message -like '*already serves*') { throw } }

New-Item -ItemType Directory -Force -Path $ScratchRoot | Out-Null
$seedCopy = Join-Path $ScratchRoot 'moos.seed.jsonl'
Copy-Item -Path $SeedLogPath -Destination $seedCopy -Force
$seedLines = (Get-Content $seedCopy | Measure-Object -Line).Lines

$kernelLog = Join-Path $ScratchRoot 'kernel.stdout.log'
$args = @('--ontology', $OntologyPath, '--log', $seedCopy,
          '--listen', (":{0}" -f $Port), '--mcp-addr', (":{0}" -f $McpPort),
          '--sweep-interval', '0')
$proc = Start-Process -FilePath $KernelExe -ArgumentList $args -WorkingDirectory $ScratchRoot `
    -WindowStyle Hidden -PassThru -RedirectStandardOutput $kernelLog -RedirectStandardError ($kernelLog + '.err')

# Wait for /healthz, then assert boot parity with the seed.
$hz = $null
foreach ($i in 1..30) {
    Start-Sleep -Milliseconds 500
    try { $hz = Invoke-RestMethod -Uri ("http://localhost:{0}/healthz" -f $Port) -TimeoutSec 2; break } catch { }
    if ($proc.HasExited) { break }
}
if (-not $hz) {
    $tail = if (Test-Path ($kernelLog + '.err')) { Get-Content ($kernelLog + '.err') -Tail 5 | Out-String } else { '' }
    throw "Scratch kernel did not become healthy on :$Port. $tail"
}

$parity = if ([int]$hz.log_len -eq $seedLines) { 'PARITY' } else { 'MISMATCH' }
Write-Host ("SCRATCH KERNEL UP — pid {0} · :{1} · log {2}/{3} seed lines [{4}] · ontology {5} · t_day {6}" -f `
    $proc.Id, $Port, $hz.log_len, $seedLines, $parity, $hz.ontology_version, $hz.t_day) -ForegroundColor $(if ($parity -eq 'PARITY') { 'Green' } else { 'Red' })
Write-Host ("  seed: {0}  (copy of {1})" -f $seedCopy, $SeedLogPath)
Write-Host ("  stop: Stop-Process -Id {0}" -f $proc.Id)
if ($parity -ne 'PARITY') {
    Write-Host '  ! log_len differs from seed line count — inspect before trusting any validation on this kernel.' -ForegroundColor Red
    exit 1
}
