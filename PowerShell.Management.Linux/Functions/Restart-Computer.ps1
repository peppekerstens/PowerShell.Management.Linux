function Restart-Computer {
    <#
    .Synopsis
        Restarts the operating system on local and remote computers.
    .Description
        Cross-platform implementation of Restart-Computer.
        On Windows, delegates to the built-in Microsoft.PowerShell.Management\Restart-Computer.
        On Linux, wraps 'shutdown -r' (requires root or sudo privilege).
    .Parameter Delay
        Number of seconds to wait before restarting. Default: 0.
    .Parameter Force
        Force all applications to close without waiting.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/microsoft.powershell.management/restart-computer
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter()]
        [int]$Delay = 0,

        [Parameter()]
        [switch]$Force
    )

    if (-not $IsLinux) {
        Microsoft.PowerShell.Management\Restart-Computer @PSBoundParameters
        return
    }

    if (-not (Get-Command shutdown -ErrorAction SilentlyContinue)) {
        throw "Restart-Computer: 'shutdown' not found."
    }

    if ($Force -or $PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Restart-Computer')) {
        if ($Delay -gt 0) {
            $minutes = [math]::Ceiling($Delay / 60)
            $output = shutdown -r "+$minutes" 2>&1
        } else {
            $output = shutdown -r now 2>&1
        }
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Restart-Computer: Failed to restart. $output"
        }
    }
}
