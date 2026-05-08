function Get-Service {
    <#
    .Synopsis
        Gets the services on a computer.
    .Description
        Cross-platform implementation of Get-Service.
        On Windows, delegates to the built-in Microsoft.PowerShell.Management\Get-Service cmdlet.
        On Linux, wraps systemctl to return service objects with properties matching the
        Windows ServiceController object shape as closely as possible.
    .Parameter Name
        The service name(s) to retrieve. Wildcards supported.
    .Parameter DisplayName
        Filter by display name. Wildcards supported.
    .Parameter Include
        Include only services matching these name patterns.
    .Parameter Exclude
        Exclude services matching these name patterns.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/microsoft.powershell.management/get-service
    #>
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ParameterSetName = 'Default', Position = 0, ValueFromPipelineByPropertyName = $true)]
        [Alias('ServiceName')]
        [string[]]$Name,

        [Parameter(ParameterSetName = 'DisplayName')]
        [string[]]$DisplayName,

        [Parameter()]
        [string[]]$Include,

        [Parameter()]
        [string[]]$Exclude
    )

    if (-not $IsLinux) {
        Microsoft.PowerShell.Management\Get-Service @PSBoundParameters
        return
    }

    if (-not (Get-Command systemctl -ErrorAction SilentlyContinue)) {
        throw "Get-Service: 'systemctl' not found. This cmdlet requires systemd."
    }

    # --- Build a hash of startup types from list-unit-files ---
    $startupHash = @{}
    $unitFileLines = systemctl list-unit-files --type=service --no-pager --no-legend --plain 2>$null
    foreach ($line in $unitFileLines) {
        $parts = $line -split '\s+', 3
        if ($parts.Count -ge 2) {
            $unitName = $parts[0] -replace '\.service$', ''
            $state    = $parts[1]
            $startType = switch ($state) {
                'enabled'          { 'Automatic' }
                'enabled-runtime'  { 'Automatic' }
                'static'           { 'Manual' }
                'indirect'         { 'Manual' }
                'disabled'         { 'Disabled' }
                'masked'           { 'Disabled' }
                'generated'        { 'Manual' }
                'transient'        { 'Manual' }
                default            { 'Unknown' }
            }
            $startupHash[$unitName] = $startType
        }
    }

    # --- Build a hash of display names and states from list-units --all ---
    $unitLines = systemctl list-units --type=service --all --no-pager --no-legend --plain 2>$null
    $serviceObjects = [System.Collections.Generic.List[PSCustomObject]]::new()

    foreach ($line in $unitLines) {
        # Format: UNIT LOAD ACTIVE SUB DESCRIPTION
        $parts = $line -split '\s+', 5
        if ($parts.Count -lt 4) { continue }
        $unit        = $parts[0] -replace '\.service$', ''
        $loadState   = $parts[1]
        $activeState = $parts[2]
        $subState    = $parts[3]
        $description = if ($parts.Count -ge 5) { $parts[4].Trim() } else { $unit }

        # Skip non-loaded placeholder entries (e.g. lines with ● prefix)
        if ($unit -match '^\s*$') { continue }

        $status = switch ("$activeState/$subState") {
            'active/running'   { 'Running' }
            'active/exited'    { 'Stopped' }
            'active/mounted'   { 'Running' }
            'inactive/dead'    { 'Stopped' }
            'failed/failed'    { 'Stopped' }
            'activating/start' { 'StartPending' }
            'deactivating/stop'{ 'StopPending' }
            default            { 'Stopped' }
        }

        $startType = if ($startupHash.ContainsKey($unit)) { $startupHash[$unit] } else { 'Unknown' }

        $serviceObjects.Add([PSCustomObject]@{
            Name                = $unit
            DisplayName         = $description
            Status              = [string]$status
            StartType           = [string]$startType
            ServiceType         = 'Own'
            CanStop             = ($status -eq 'Running')
            CanPauseAndContinue = $false
            CanShutdown         = $false
            DependentServices   = @()
            ServicesDependedOn  = @()
        })
    }

    # Also add services that appear in unit-files but weren't in list-units (inactive/never started)
    foreach ($unitName in $startupHash.Keys) {
        if (-not ($serviceObjects | Where-Object { $_.Name -eq $unitName })) {
            $serviceObjects.Add([PSCustomObject]@{
                Name                = $unitName
                DisplayName         = $unitName
                Status              = 'Stopped'
                StartType           = $startupHash[$unitName]
                ServiceType         = 'Own'
                CanStop             = $false
                CanPauseAndContinue = $false
                CanShutdown         = $false
                DependentServices   = @()
                ServicesDependedOn  = @()
            })
        }
    }

    $results = $serviceObjects

    # --- Apply filters ---
    if ($PSCmdlet.ParameterSetName -eq 'DisplayName') {
        $results = $results | Where-Object {
            $dn = $_.DisplayName
            $DisplayName | Where-Object { $dn -like $_ }
        }
    } elseif ($PSBoundParameters.ContainsKey('Name')) {
        $results = $results | Where-Object {
            $n = $_.Name
            $Name | Where-Object { $n -like $_ }
        }
    }

    if ($PSBoundParameters.ContainsKey('Include')) {
        $results = $results | Where-Object {
            $n = $_.Name
            $Include | Where-Object { $n -like $_ }
        }
    }

    if ($PSBoundParameters.ContainsKey('Exclude')) {
        $results = $results | Where-Object {
            $n = $_.Name
            -not ($Exclude | Where-Object { $n -like $_ })
        }
    }

    $results
}
