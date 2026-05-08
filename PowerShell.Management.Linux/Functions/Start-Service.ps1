function Start-Service {
    <#
    .Synopsis
        Starts one or more stopped services.
    .Description
        Cross-platform implementation of Start-Service.
        On Windows, delegates to the built-in Microsoft.PowerShell.Management\Start-Service.
        On Linux, wraps 'systemctl start'.
    .Parameter Name
        The service name(s) to start.
    .Parameter InputObject
        ServiceController objects (from Get-Service) to start. Accepts pipeline input.
    .Parameter PassThru
        Return a service object for each service started.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/microsoft.powershell.management/start-service
    #>
    [CmdletBinding(DefaultParameterSetName = 'Name', SupportsShouldProcess = $true)]
    param(
        [Parameter(ParameterSetName = 'Name', Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [Alias('ServiceName')]
        [string[]]$Name,

        [Parameter(ParameterSetName = 'InputObject', Mandatory = $true, ValueFromPipeline = $true)]
        [PSObject[]]$InputObject,

        [Parameter()]
        [switch]$PassThru
    )

    process {
        if (-not $IsLinux) {
            if ($PSCmdlet.ParameterSetName -eq 'InputObject') {
                $InputObject | Microsoft.PowerShell.Management\Start-Service -PassThru:$PassThru
            } else {
                Microsoft.PowerShell.Management\Start-Service -Name $Name -PassThru:$PassThru
            }
            return
        }

        if (-not (Get-Command systemctl -ErrorAction SilentlyContinue)) {
            throw "Start-Service: 'systemctl' not found. This cmdlet requires systemd."
        }

        $serviceNames = if ($PSCmdlet.ParameterSetName -eq 'InputObject') {
            $InputObject | ForEach-Object { $_.Name }
        } else { $Name }

        foreach ($svc in $serviceNames) {
            if ($PSCmdlet.ShouldProcess($svc, 'Start-Service')) {
                $output = systemctl start "$svc" 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "Start-Service: Failed to start '$svc'. $output"
                } else {
                    Write-Verbose "Start-Service: '$svc' started successfully."
                    if ($PassThru) { Get-Service -Name $svc }
                }
            }
        }
    }
}
