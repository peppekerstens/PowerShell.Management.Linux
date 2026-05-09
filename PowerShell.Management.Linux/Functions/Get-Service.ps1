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

    process {
    if (-not $IsLinux) {
        Microsoft.PowerShell.Management\Get-Service @PSBoundParameters
        return
    }

    # --- Build a hash of startup types from list-unit-files (JSON) ---
    $startupHash   = @{}
    $unitFileJson  = systemctl list-unit-files --type=service --output=json --no-pager 2>$null
    if ($unitFileJson) {
        ($unitFileJson | ConvertFrom-Json) | ForEach-Object {
            $unitName  = $_.unit_file -replace '\.service$', ''
            $startType = switch ($_.state) {
                'enabled'         { 'Automatic' }
                'enabled-runtime' { 'Automatic' }
                'static'          { 'Manual' }
                'indirect'        { 'Manual' }
                'disabled'        { 'Disabled' }
                'masked'          { 'Disabled' }
                'generated'       { 'Manual' }
                'transient'       { 'Manual' }
                default           { 'Unknown' }
            }
            $startupHash[$unitName] = $startType
        }
    }

    # --- Build service objects from list-units --all (JSON) ---
    $unitJson       = systemctl list-units --type=service --all --output=json --no-pager 2>$null
    $seenNames      = [System.Collections.Generic.HashSet[string]]::new()
    $serviceObjects = [System.Collections.Generic.List[PSCustomObject]]::new()

    if ($unitJson) {
        ($unitJson | ConvertFrom-Json) | ForEach-Object {
            $unit        = $_.unit -replace '\.service$', ''
            $activeState = $_.active
            $subState    = $_.sub
            $description = if ($_.description) { $_.description } else { $unit }

            $status = switch ("$activeState/$subState") {
                'active/running'    { 'Running' }
                'active/exited'     { 'Stopped' }
                'active/mounted'    { 'Running' }
                'inactive/dead'     { 'Stopped' }
                'failed/failed'     { 'Stopped' }
                'activating/start'  { 'StartPending' }
                'deactivating/stop' { 'StopPending' }
                default             { 'Stopped' }
            }

            $startType = if ($startupHash.ContainsKey($unit)) { $startupHash[$unit] } else { 'Unknown' }
            [void]$seenNames.Add($unit)

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
    }

    # Also add services that appear in unit-files but weren't in list-units (inactive/never started)
    foreach ($unitName in $startupHash.Keys) {
        if (-not $seenNames.Contains($unitName)) {
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
    } # end process
}
