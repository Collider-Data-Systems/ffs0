[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [int]$KeepMorphismBackups = 3
)

$workspaceRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$parentRoot = Split-Path -Parent $workspaceRoot
$moosRoot = Join-Path $parentRoot 'moos'

function Remove-WorkspaceFile {
    param(
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    if ($PSCmdlet.ShouldProcess($Path, 'Remove file')) {
        Remove-Item -LiteralPath $Path -Force
    }
}

function Remove-WorkspaceMatches {
    param(
        [string]$Pattern
    )

    Get-ChildItem -Path $Pattern -File -ErrorAction SilentlyContinue | ForEach-Object {
        if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove file')) {
            Remove-Item -LiteralPath $_.FullName -Force
        }
    }
}

function Remove-EmptyDirectoryChain {
    param(
        [string]$StartPath,
        [string]$StopPath
    )

    $current = $StartPath
    while ($current -and (Test-Path -LiteralPath $current)) {
        $resolvedCurrent = [System.IO.Path]::GetFullPath($current)
        $resolvedStop = [System.IO.Path]::GetFullPath($StopPath)
        if ($resolvedCurrent -eq $resolvedStop) {
            break
        }

        $children = Get-ChildItem -LiteralPath $current -Force -ErrorAction SilentlyContinue
        if ($children.Count -gt 0) {
            break
        }

        if ($PSCmdlet.ShouldProcess($current, 'Remove empty directory')) {
            Remove-Item -LiteralPath $current -Force
        }
        $current = Split-Path -Parent $current
    }
}

$kernelRoot = Join-Path $moosRoot 'platform\kernel'
$agentDevRoot = Join-Path $workspaceRoot '.agent\dev'
$agentDataRoot = Join-Path $workspaceRoot '.agent\data'

Remove-WorkspaceMatches (Join-Path $kernelRoot 'boot*.log')
Remove-WorkspaceMatches (Join-Path $kernelRoot '*.out')
Remove-WorkspaceFile (Join-Path $kernelRoot 'temp.xml')
Remove-WorkspaceFile (Join-Path $kernelRoot 'moos.exe~')
Remove-WorkspaceFile (Join-Path $kernelRoot 'moos-stdout.log')

Remove-WorkspaceMatches (Join-Path $agentDevRoot 'wave*.json')
Remove-WorkspaceMatches (Join-Path $agentDevRoot 'prg*-program.json')

$staleState = Join-Path $kernelRoot 'ffs0-factory-super\.agent\dev\.antigraviti-auto-listener-state.json'
if (Test-Path -LiteralPath $staleState) {
    Remove-WorkspaceFile $staleState
    Remove-EmptyDirectoryChain -StartPath (Split-Path -Parent $staleState) -StopPath $kernelRoot
}

$backupFiles = Get-ChildItem -Path (Join-Path $agentDataRoot 'morphism-log.jsonl.bak*') -File -ErrorAction SilentlyContinue |
Sort-Object LastWriteTime -Descending

$backupFiles | Select-Object -Skip $KeepMorphismBackups | ForEach-Object {
    if ($PSCmdlet.ShouldProcess($_.FullName, 'Prune old morphism backup')) {
        Remove-Item -LiteralPath $_.FullName -Force
    }
}