function Remove-Service {
    <#
    .SYNOPSIS
        Removes a systemd service unit. On Linux, stops, disables, and deletes the unit file.
    .DESCRIPTION
        Runs 'systemctl stop', 'systemctl disable', removes the unit file from
        /etc/systemd/system/, then runs 'systemctl daemon-reload'.
        Requires sudo privileges on Linux.

        Note: Only services whose unit files reside in /etc/systemd/system/ can be removed.
        Vendor-managed units (in /lib/systemd/system/) are not removed.
    .PARAMETER Name
        The service (unit) name. The '.service' suffix is added automatically if not present.
    .LINK
        https://learn.microsoft.com/powershell/module/microsoft.powershell.management/remove-service
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipelineByPropertyName = $true)]
        [string]$Name
    )
    process {
        if ($IsLinux) {
            $unitName = if ($Name -match '\.service$') { $Name } else { "$Name.service" }
            $unitPath = "/etc/systemd/system/$unitName"

            if ($PSCmdlet.ShouldProcess($unitName, 'Stop, disable, and delete systemd service unit')) {
                & sudo systemctl stop $unitName 2>&1 | Out-Null
                & sudo systemctl disable $unitName 2>&1 | Out-Null

                if (Test-Path $unitPath) {
                    & sudo rm -f $unitPath
                    if ($LASTEXITCODE -ne 0) {
                        Write-Error "Failed to remove unit file $unitPath"
                        return
                    }
                } else {
                    Write-Warning "Remove-Service: unit file '$unitPath' not found. Only services in /etc/systemd/system/ can be removed."
                }
                & sudo systemctl daemon-reload
            }
        } else {
            Microsoft.PowerShell.Management\Remove-Service @PSBoundParameters
        }
    }
}
