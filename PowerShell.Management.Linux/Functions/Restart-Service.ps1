function Restart-Service {
    <#
    .Synopsis
        Stops and then starts one or more services.
    .Description
        Cross-platform implementation of Restart-Service.
        On Windows, delegates to the built-in Microsoft.PowerShell.Management\Restart-Service.
        On Linux, wraps 'systemctl restart'.
    .Parameter Name
        The service name(s) to restart.
    .Parameter InputObject
        ServiceController objects (from Get-Service) to restart. Accepts pipeline input.
    .Parameter PassThru
        Return a service object for each service restarted.
    .Parameter Force
        Restart even if the service has dependent services.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/microsoft.powershell.management/restart-service
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
        [switch]$Force
    )

    process {
        if (-not $IsLinux) {
            if ($PSCmdlet.ParameterSetName -eq 'InputObject') {
                $InputObject | Microsoft.PowerShell.Management\Restart-Service -PassThru:$PassThru -Force:$Force
            } else {
                Microsoft.PowerShell.Management\Restart-Service -Name $Name -PassThru:$PassThru -Force:$Force
            }
            return
        }

        if (-not (Get-Command systemctl -ErrorAction SilentlyContinue)) {
            throw "Restart-Service: 'systemctl' not found. This cmdlet requires systemd."
        }

        $serviceNames = if ($PSCmdlet.ParameterSetName -eq 'InputObject') {
            $InputObject | ForEach-Object { $_.Name }
        } else { $Name }

        foreach ($svc in $serviceNames) {
            if ($PSCmdlet.ShouldProcess($svc, 'Restart-Service')) {
                $output = systemctl restart "$svc" 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "Restart-Service: Failed to restart '$svc'. $output"
                } else {
                    Write-Verbose "Restart-Service: '$svc' restarted successfully."
                    if ($PassThru) { Get-Service -Name $svc }
                }
            }
        }
    }
}
