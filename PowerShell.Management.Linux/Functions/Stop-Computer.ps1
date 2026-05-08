function Stop-Computer {
    <#
    .Synopsis
        Stops (shuts down) local and remote computers.
    .Description
        Cross-platform implementation of Stop-Computer.
        On Windows, delegates to the built-in Microsoft.PowerShell.Management\Stop-Computer.
        On Linux, wraps 'shutdown -h' (requires root or sudo privilege).
    .Parameter Delay
        Number of seconds to wait before shutting down. Default: 0.
    .Parameter Force
        Force all applications to close without waiting.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/microsoft.powershell.management/stop-computer
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter()]
        [int]$Delay = 0,

        [Parameter()]
        [switch]$Force
    )

    if (-not $IsLinux) {
        Microsoft.PowerShell.Management\Stop-Computer @PSBoundParameters
        return
    }

    if (-not (Get-Command shutdown -ErrorAction SilentlyContinue)) {
        throw "Stop-Computer: 'shutdown' not found."
    }

    if ($Force -or $PSCmdlet.ShouldProcess($env:COMPUTERNAME, 'Stop-Computer')) {
        if ($Delay -gt 0) {
            $minutes = [math]::Ceiling($Delay / 60)
            $output = shutdown -h "+$minutes" 2>&1
        } else {
            $output = shutdown -h now 2>&1
        }
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Stop-Computer: Failed to shutdown. $output"
        }
    }
}
