[CmdletBinding()]
param(
    [ValidateSet('Doctor', 'Start', 'VerifyPersona', 'PostProgram')]
    [string]$Mode = 'Doctor',

    [ValidateSet('wolfram', 'steinberger', 'karpathy', 'moos', 'zappa', 'cowork-z440', 'z440-vscode-lead', 'john-lydon', 'guido', 'cowork-laptop', 'ag-laptop', 'hpprodesk-vscode')]
    [string]$Persona,

    [string]$PayloadPath,
    [string]$TopologyPath,
    [string]$McpConfigPath,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# T244+: persona key rename cowork-z440 -> zappa; accept the legacy key as an alias.
if ($Persona -eq 'cowork-z440') { $Persona = 'zappa' }

# T247 seat split: 'guido' is a live persona key again (laptop VS Code lead seat);
# governance is 'john-lydon'. No alias shim — both keys resolve directly from topology.

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..\..')
if (-not $TopologyPath) {
    $TopologyPath = Join-Path $RepoRoot 'dev\config\moos-federation.topology.json'
}
if (-not $McpConfigPath) {
    $McpConfigPath = Join-Path $RepoRoot '.vscode\mcp.json'
}

function Read-JsonFile {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) {
        throw "Missing JSON file: $Path"
    }
    Get-Content -Path $Path -Raw | ConvertFrom-Json
}

function Get-ObjectProperty {
    param(
        [Parameter(Mandatory)]$Object,
        [Parameter(Mandatory)][string]$Name
    )
    $property = $Object.PSObject.Properties[$Name]
    if ($null -eq $property) { return $null }
    $property.Value
}

function Get-NormalizedHostName {
    $raw = if ($env:MOOS_LOCAL_HOST) { [string]$env:MOOS_LOCAL_HOST } else { [string]$env:COMPUTERNAME }
    $hostName = $raw.Trim().ToLowerInvariant()
    switch -Regex ($hostName) {
        '^(hp[-_]?laptop|hplaptop|lap[-_]?sam)$' { return 'hp-laptop' }
        '^(hp[-_]?z440|hpz440)$' { return 'hp-z440' }
        '^(hp[-_]?prodesk|hpprodesk|desktop[-_]?3fc7c3f)$' { return 'hpprodesk' }
        default { return $hostName }
    }
}

function Resolve-TopologyLocalHost {
    param([Parameter(Mandatory)]$Topology)
    $configured = if ($Topology.local_host) { [string]$Topology.local_host } else { 'auto' }
    if ($configured -eq 'auto') { return Get-NormalizedHostName }
    $configured
}

function Get-KernelUrl {
    param([Parameter(Mandatory)]$Kernel)
    if ($Kernel.http_local -and $Kernel.host -eq $script:MoosLocalHost) { return [string]$Kernel.http_local }
    if ($Kernel.http_lan) { return [string]$Kernel.http_lan }
    if ($Kernel.http_local) { return [string]$Kernel.http_local }
    throw "Kernel $($Kernel.urn) has no http_local or http_lan URL"
}

function Get-RouterUrl {
    param([Parameter(Mandatory)]$Router)
    if ($Router.http_local -and $Router.host -eq $script:MoosLocalHost) { return [string]$Router.http_local }
    if ($Router.http_lan) { return [string]$Router.http_lan }
    if ($Router.http_local) { return [string]$Router.http_local }
    throw 'Router has no http_local or http_lan URL'
}

function Get-ExpectedOntologyVersion {
    param(
        [Parameter(Mandatory)]$Topology,
        [Parameter(Mandatory)]$Kernel
    )
    if ($Kernel.expected_ontology_version) { return [string]$Kernel.expected_ontology_version }
    [string]$Topology.expected_ontology_version
}

function Resolve-MoosPath {
    param([Parameter(Mandatory)][string]$Path)
    if (Test-Path $Path) { return (Resolve-Path $Path).Path }
    $repoRelative = Join-Path $RepoRoot $Path
    if (Test-Path $repoRelative) { return (Resolve-Path $repoRelative).Path }
    return $Path
}

function Test-TcpEndpoint {
    param([Parameter(Mandatory)][string]$Url)
    try {
        $uri = [uri]$Url
        $port = if ($uri.Port -gt 0) { $uri.Port } elseif ($uri.Scheme -eq 'https') { 443 } else { 80 }
        $client = [System.Net.Sockets.TcpClient]::new()
        $async = $client.BeginConnect($uri.Host, $port, $null, $null)
        $ok = $async.AsyncWaitHandle.WaitOne(1000, $false)
        if (-not $ok) {
            $client.Close()
            return $false
        }
        $client.EndConnect($async)
        $client.Close()
        return $true
    }
    catch {
        return $false
    }
}

function Invoke-MoosGet {
    param(
        [Parameter(Mandatory)][string]$BaseUrl,
        [Parameter(Mandatory)][string]$Path
    )
    $url = $BaseUrl.TrimEnd('/') + '/' + $Path.TrimStart('/')
    Invoke-RestMethod -Uri $url -TimeoutSec 5
}

function Test-KernelHealth {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Kernel,
        [Parameter(Mandatory)]$Topology
    )
    $baseUrl = Get-KernelUrl -Kernel $Kernel
    $expectedOntologyVersion = Get-ExpectedOntologyVersion -Topology $Topology -Kernel $Kernel
    $result = [ordered]@{
        Kernel = $Name
        Url = $baseUrl
        Urn = $Kernel.urn
        Status = 'unknown'
        Ontology = ''
        LogLen = ''
        Derivation = 'unknown'
        Error = ''
    }

    try {
        $health = Invoke-MoosGet -BaseUrl $baseUrl -Path 'healthz'
        $result.Status = [string]$health.status
        $result.Ontology = [string]$health.ontology_version
        $result.LogLen = [string]$health.log_len
        if ($expectedOntologyVersion -and $result.Ontology -ne $expectedOntologyVersion) {
            $result.Error = "expected ontology $expectedOntologyVersion"
        }

        $nodeTypes = Invoke-MoosGet -BaseUrl $baseUrl -Path 'operad/node-types'
        $result.Derivation = if ($nodeTypes.PSObject.Properties['derivation']) { 'yes' } else { 'missing' }
    }
    catch {
        $result.Status = 'error'
        $result.Error = $_.Exception.Message
    }

    [pscustomobject]$result
}

function Test-RouterHealth {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)]$Router
    )
    $baseUrl = Get-RouterUrl -Router $Router
    $result = [ordered]@{
        Router = $Name
        Url = $baseUrl
        Status = 'unknown'
        Kernels = 0
        Peers = if ($Router.peers) { ($Router.peers -join ', ') } else { '' }
        Error = ''
    }

    try {
        $health = Invoke-MoosGet -BaseUrl $baseUrl -Path 'healthz'
        $result.Status = [string]$health.status
        $result.Kernels = @($health.kernels).Count
    }
    catch {
        $result.Status = 'error'
        $result.Error = $_.Exception.Message
    }

    [pscustomobject]$result
}

function Test-RouterNode {
    param(
        [Parameter(Mandatory)][string]$RouterName,
        [Parameter(Mandatory)]$Router,
        [Parameter(Mandatory)][string]$NodeUrn
    )
    $baseUrl = Get-RouterUrl -Router $Router
    $result = [ordered]@{
        Router = $RouterName
        Url = $baseUrl
        Node = $NodeUrn
        Status = 'unknown'
        NodeStatus = ''
        Error = ''
    }

    try {
        $nodePath = 'state/nodes/' + [uri]::EscapeDataString($NodeUrn)
        $node = Invoke-MoosGet -BaseUrl $baseUrl -Path $nodePath
        $result.Status = 'ok'
        $statusProperty = $node.properties.PSObject.Properties['status']
        if ($statusProperty) { $result.NodeStatus = [string]$statusProperty.Value.value }
    }
    catch {
        $result.Status = 'missing'
        $result.Error = $_.Exception.Message
    }

    [pscustomobject]$result
}

function Test-CloudflareTopology {
    param([Parameter(Mandatory)]$Cloudflare)
    $startup = if ($Cloudflare.startup_bat) { [string]$Cloudflare.startup_bat } else { '' }
    $config = if ($Cloudflare.config_path) { [string]$Cloudflare.config_path } else { '' }
    [pscustomobject]@{
        TunnelId = [string]$Cloudflare.tunnel_id
        StartupBat = $startup
        StartupExists = if ($startup) { Test-Path $startup } else { $false }
        ConfigPath = $config
        ConfigExists = if ($config) { Test-Path $config } else { $false }
        Hostnames = if ($Cloudflare.hostnames) { ($Cloudflare.hostnames.PSObject.Properties.Value -join ', ') } else { '' }
    }
}

function Test-McpConfig {
    param(
        [Parameter(Mandatory)]$Topology,
        [Parameter(Mandatory)][string]$Path
    )
    if (-not (Test-Path $Path)) {
        Write-Warning "No MCP config found at $Path"
        return
    }

    $config = Read-JsonFile -Path $Path
    foreach ($serverProperty in $Topology.mcp_servers.PSObject.Properties) {
        $name = $serverProperty.Name
        $expectedUrl = [string]$serverProperty.Value
        $server = Get-ObjectProperty -Object $config.servers -Name $name
        $alias = $null
        if (-not $server) {
            $alias = $config.servers.PSObject.Properties | Where-Object { [string]$_.Value.url -eq $expectedUrl } | Select-Object -First 1
        }
        $actualUrl = if ($server) { [string]$server.url } elseif ($alias) { [string]$alias.Value.url } else { '' }
        $status = if ($server -and $actualUrl -eq $expectedUrl) {
            'ok'
        }
        elseif ($alias) {
            "alias:$($alias.Name)"
        }
        elseif ($actualUrl) {
            'mismatch'
        }
        else {
            'missing'
        }
        [pscustomobject]@{
            Server = $name
            ExpectedUrl = $expectedUrl
            ActualUrl = $actualUrl
            TcpReachable = if ($actualUrl) { Test-TcpEndpoint -Url $actualUrl } else { $false }
            Status = $status
        }
    }
}

function Get-PersonaKernelName {
    param(
        [Parameter(Mandatory)]$PersonaConfig,
        [ValidateSet('Emit', 'OpensOn')][string]$Kind
    )
    if ($Kind -eq 'Emit') {
        if ($PersonaConfig.emit_kernel) { return [string]$PersonaConfig.emit_kernel }
        if ($PersonaConfig.state_kernel) { return [string]$PersonaConfig.state_kernel }
        if ($PersonaConfig.kernel) { return [string]$PersonaConfig.kernel }
    }
    if ($PersonaConfig.opens_on_kernel) { return [string]$PersonaConfig.opens_on_kernel }
    if ($PersonaConfig.kernel) { return [string]$PersonaConfig.kernel }
    if ($PersonaConfig.emit_kernel) { return [string]$PersonaConfig.emit_kernel }
    throw 'Persona has no kernel mapping'
}

function Resolve-Persona {
    param(
        [Parameter(Mandatory)]$Topology,
        [Parameter(Mandatory)][string]$Name
    )
    $personaConfig = Get-ObjectProperty -Object $Topology.personas -Name $Name
    if (-not $personaConfig) {
        throw "Unknown persona '$Name'"
    }

    $emitKernelName = Get-PersonaKernelName -PersonaConfig $personaConfig -Kind Emit
    $opensOnKernelName = Get-PersonaKernelName -PersonaConfig $personaConfig -Kind OpensOn
    $emitKernel = Get-ObjectProperty -Object $Topology.kernels -Name $emitKernelName
    $opensOnKernel = Get-ObjectProperty -Object $Topology.kernels -Name $opensOnKernelName
    if (-not $emitKernel) {
        throw "Persona '$Name' references unknown emit kernel '$emitKernelName'"
    }
    if (-not $opensOnKernel) {
        throw "Persona '$Name' references unknown opens-on kernel '$opensOnKernelName'"
    }

    [pscustomobject]@{
        Name = $Name
        Config = $personaConfig
        EmitKernelName = $emitKernelName
        OpensOnKernelName = $opensOnKernelName
        EmitKernel = $emitKernel
        OpensOnKernel = $opensOnKernel
        EmitUrl = Get-KernelUrl -Kernel $emitKernel
        OpensOnUrl = Get-KernelUrl -Kernel $opensOnKernel
    }
}

function Test-Persona {
    param(
        [Parameter(Mandatory)]$Topology,
        [Parameter(Mandatory)][string]$Name
    )
    $resolved = Resolve-Persona -Topology $Topology -Name $Name
    $rows = @()
    $rows += [pscustomobject]@{ Check = 'emit-kernel'; Target = $resolved.EmitKernelName; Status = 'ok'; Detail = $resolved.EmitUrl }
    $rows += [pscustomobject]@{ Check = 'opens-on-kernel'; Target = $resolved.OpensOnKernelName; Status = 'topology'; Detail = $resolved.OpensOnUrl }
    $rows += [pscustomobject]@{ Check = 'actor'; Target = $resolved.Config.actor_urn; Status = 'declared'; Detail = '' }
    $rows += [pscustomobject]@{ Check = 'session'; Target = $resolved.Config.session_urn; Status = 'declared'; Detail = '' }

    $mcpServer = Get-ObjectProperty -Object $Topology.mcp_servers -Name $resolved.Config.mcp_server
    if ($mcpServer) {
        $rows += [pscustomobject]@{ Check = 'mcp-target'; Target = $resolved.Config.mcp_server; Status = if (Test-TcpEndpoint -Url $mcpServer) { 'ok' } else { 'unreachable' }; Detail = $mcpServer }
    }
    else {
        $rows += [pscustomobject]@{ Check = 'mcp-target'; Target = $resolved.Config.mcp_server; Status = 'missing'; Detail = 'not present in topology.mcp_servers' }
    }

    $topologyMcpName = if ($resolved.Config.topology_mcp_server) { [string]$resolved.Config.topology_mcp_server } else { '' }
    if ($topologyMcpName) {
        $topologyMcp = Get-ObjectProperty -Object $Topology.mcp_servers -Name $topologyMcpName
        $rows += [pscustomobject]@{ Check = 'opens-on-mcp'; Target = $topologyMcpName; Status = if ($topologyMcp) { 'topology' } else { 'missing' }; Detail = if ($topologyMcp) { $topologyMcp } else { 'not present in topology.mcp_servers' } }
    }

    try {
        $sessionPath = 'state/nodes/' + [uri]::EscapeDataString([string]$resolved.Config.session_urn)
        $sessionNode = Invoke-MoosGet -BaseUrl $resolved.EmitUrl -Path $sessionPath
        $rows += [pscustomobject]@{ Check = 'session-on-receiving-kernel'; Target = $resolved.Config.session_urn; Status = 'ok'; Detail = $sessionNode.type_id }
    }
    catch {
        $rows += [pscustomobject]@{ Check = 'session-on-receiving-kernel'; Target = $resolved.Config.session_urn; Status = 'missing'; Detail = $_.Exception.Message }
    }

    try {
        $relationsPath = 'state/relations/src/' + [uri]::EscapeDataString([string]$resolved.Config.session_urn)
        $relations = @(Invoke-MoosGet -BaseUrl $resolved.EmitUrl -Path $relationsPath)
        $occupant = $relations | Where-Object { $_.src_port -eq 'has-occupant' -and $_.tgt_urn -eq $resolved.Config.actor_urn } | Select-Object -First 1
        $opensOn = $relations | Where-Object { $_.src_port -eq 'opens-on' -and $_.tgt_urn -eq $resolved.OpensOnKernel.urn } | Select-Object -First 1
        $rows += [pscustomObject]@{ Check = 'has-occupant'; Target = $resolved.Config.actor_urn; Status = if ($occupant) { 'ok' } else { 'missing' }; Detail = "checked on $($resolved.EmitUrl)" }
        $rows += [pscustomObject]@{ Check = 'opens-on-link'; Target = $resolved.OpensOnKernel.urn; Status = if ($opensOn) { 'ok' } else { 'missing' }; Detail = 'topology intent stored on receiving kernel' }
    }
    catch {
        $rows += [pscustomObject]@{ Check = 'has-occupant'; Target = $resolved.Config.actor_urn; Status = 'error'; Detail = $_.Exception.Message }
        $rows += [pscustomObject]@{ Check = 'opens-on-link'; Target = $resolved.OpensOnKernel.urn; Status = 'error'; Detail = $_.Exception.Message }
    }

    try {
        $health = Invoke-MoosGet -BaseUrl $resolved.EmitUrl -Path 'healthz'
        $rows += [pscustomobject]@{ Check = 'health'; Target = $resolved.EmitUrl; Status = $health.status; Detail = "ontology=$($health.ontology_version) log_len=$($health.log_len)" }
    }
    catch {
        $rows += [pscustomobject]@{ Check = 'health'; Target = $resolved.EmitUrl; Status = 'error'; Detail = $_.Exception.Message }
    }

    $rows
}

function ConvertTo-ProgramJsonArray {
    param(
        [Parameter(Mandatory)][array]$Envelopes,
        [int]$Depth = 50
    )

    if ($Envelopes.Count -eq 0) {
        throw 'Program payload must contain at least one envelope.'
    }

    $items = foreach ($envelope in $Envelopes) {
        ConvertTo-Json -InputObject $envelope -Depth $Depth -Compress
    }

    '[' + ($items -join ',') + ']'
}

function Get-ProgramEnvelopes {
    param([Parameter(Mandatory)]$Payload)

    if (($Payload -isnot [array]) -and $Payload.PSObject.Properties['envelopes']) {
        $source = $Payload.envelopes
    }
    else {
        $source = $Payload
    }

    if ($null -eq $source) { return @() }
    @($source)
}

function Invoke-PostProgram {
    param(
        [Parameter(Mandatory)]$Topology,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$Path,
        [switch]$Force
    )
    $Path = Resolve-MoosPath -Path $Path
    if (-not (Test-Path $Path)) {
        throw "Payload not found: $Path"
    }

    $resolved = Resolve-Persona -Topology $Topology -Name $Name
    $preflight = Test-Persona -Topology $Topology -Name $Name
    $blockingChecks = @('mcp-target', 'session-on-receiving-kernel', 'has-occupant', 'opens-on-link', 'health')
    $blocking = @($preflight | Where-Object { $blockingChecks -contains $_.Check -and $_.Status -ne 'ok' })
    if ($blocking.Count -gt 0 -and -not $Force) {
        $blocking | Format-Table -AutoSize | Out-String | Write-Host
        throw "Preflight failed for persona '$Name'. Re-run with -Force to POST anyway."
    }

    $json = Read-JsonFile -Path $Path
    $envelopes = @(Get-ProgramEnvelopes -Payload $json)
    $body = ConvertTo-ProgramJsonArray -Envelopes $envelopes -Depth 50
    $url = $resolved.EmitUrl.TrimEnd('/') + '/programs'

    Write-Host "POST $Path -> $url as persona '$Name' (emit=$($resolved.EmitKernelName), opens-on=$($resolved.OpensOnKernelName))" -ForegroundColor Cyan
    Invoke-RestMethod -Uri $url -Method Post -Body $body -ContentType 'application/json' | ConvertTo-Json -Depth 20
}

$topology = Read-JsonFile -Path $TopologyPath
$script:MoosLocalHost = Resolve-TopologyLocalHost -Topology $topology

switch ($Mode) {
    'Doctor' {
        Write-Host "Topology: $TopologyPath" -ForegroundColor Cyan
        Write-Host "MCP config: $McpConfigPath" -ForegroundColor Cyan
        Write-Host "Local host: $script:MoosLocalHost" -ForegroundColor Cyan
        Write-Host ''
        Write-Host 'Kernel health' -ForegroundColor Cyan
        $kernelResults = foreach ($kernelProperty in $topology.kernels.PSObject.Properties) {
            Test-KernelHealth -Name $kernelProperty.Name -Kernel $kernelProperty.Value -Topology $topology
        }
        $kernelResults | Format-Table -AutoSize

        Write-Host ''
        if ($topology.PSObject.Properties['routers']) {
            Write-Host 'Router federation' -ForegroundColor Cyan
            $routerResults = foreach ($routerProperty in $topology.routers.PSObject.Properties) {
                Test-RouterHealth -Name $routerProperty.Name -Router $routerProperty.Value
            }
            $routerResults | Format-Table -AutoSize

            Write-Host ''
            Write-Host 'Federated node lookup' -ForegroundColor Cyan
            $probeUrns = @(
                'urn:moos:session:sam.governance',
                'urn:moos:session:sam.z440-vscode-projection-lead'
            )
            $nodeResults = foreach ($routerProperty in $topology.routers.PSObject.Properties) {
                foreach ($probeUrn in $probeUrns) {
                    Test-RouterNode -RouterName $routerProperty.Name -Router $routerProperty.Value -NodeUrn $probeUrn
                }
            }
            $nodeResults | Format-Table -AutoSize

            Write-Host ''
        }
        if ($topology.PSObject.Properties['cloudflare']) {
            Write-Host 'Cloudflare tunnel metadata' -ForegroundColor Cyan
            Test-CloudflareTopology -Cloudflare $topology.cloudflare | Format-Table -AutoSize
            Write-Host ''
        }

        Write-Host ''
        Write-Host 'MCP config' -ForegroundColor Cyan
        Test-McpConfig -Topology $topology -Path $McpConfigPath | Format-Table -AutoSize
    }
    'Start' {
        $startScript = $topology.scripts.z440_start_federation
        if (-not (Test-Path $startScript)) {
            throw "Z440 federation start script not found: $startScript"
        }
        & $startScript
        & $PSCommandPath -Mode Doctor -TopologyPath $TopologyPath -McpConfigPath $McpConfigPath
    }
    'VerifyPersona' {
        if (-not $Persona) { throw '-Persona is required for VerifyPersona' }
        Test-Persona -Topology $topology -Name $Persona | Format-Table -AutoSize
    }
    'PostProgram' {
        if (-not $Persona) { throw '-Persona is required for PostProgram' }
        if (-not $PayloadPath) { throw '-PayloadPath is required for PostProgram' }
        Invoke-PostProgram -Topology $topology -Name $Persona -Path $PayloadPath -Force:$Force
    }
}