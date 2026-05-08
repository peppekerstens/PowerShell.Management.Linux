function Stop-Service {
    <#
    .Synopsis
        Stops one or more running services.
    .Description
        Cross-platform implementation of Stop-Service.
        On Windows, delegates to the built-in Microsoft.PowerShell.Management\Stop-Service.
        On Linux, wraps 'systemctl stop'.
    .Parameter Name
        The service name(s) to stop.
    .Parameter InputObject
        ServiceController objects (from Get-Service) to stop. Accepts pipeline input.
    .Parameter PassThru
        Return a service object for each service stopped.
    .Parameter Force
        Force stop even if the service has dependent services.
    .Parameter NoWait
        Do not wait for the stop operation to complete.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/microsoft.powershell.management/stop-service
    #>
    [CmdletBinding(DefaultParameterSetName = 'Name', SupportsShouldProcess = $true)]
    param(
        [Parameter(ParameterSetName = 'Name', Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [Alias('ServiceName')]
        [string[]]$Name,

        [Parameter(ParameterSetName = 'InputObject', Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject[]]$InputObject,

        [Parameter()]
        [switch]$PassThru,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$NoWait
    )

    process {
        if (-not $IsLinux) {
            $params = @{}
            if ($PSCmdlet.ParameterSetName -eq 'InputObject') {
                $InputObject | Microsoft.PowerShell.Management\Stop-Service -PassThru:$PassThru -Force:$Force
            } else {
                Microsoft.PowerShell.Management\Stop-Service -Name $Name -PassThru:$PassThru -Force:$Force
            }
            return
        }

        if (-not (Get-Command systemctl -ErrorAction SilentlyContinue)) {
            throw "Stop-Service: 'systemctl' not found. This cmdlet requires systemd."
        }

        $serviceNames = if ($PSCmdlet.ParameterSetName -eq 'InputObject') {
            $InputObject | ForEach-Object { $_.Name }
        } else { $Name }

        foreach ($svc in $serviceNames) {
            if ($PSCmdlet.ShouldProcess($svc, 'Stop-Service')) {
                $output = systemctl stop "$svc" 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "Stop-Service: Failed to stop '$svc'. $output"
                } else {
                    Write-Verbose "Stop-Service: '$svc' stopped successfully."
                    if ($PassThru) { Get-Service -Name $svc }
                }
            }
        }
    }
}
