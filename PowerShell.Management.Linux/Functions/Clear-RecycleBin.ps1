function Clear-RecycleBin {
    <#
    .Synopsis
        Not yet implemented on Linux. Delegates to Microsoft.PowerShell.Management\Clear-RecycleBin on Windows.
    .Notes
        This is a compatibility stub. On Linux a Write-Warning is emitted.
        Contributions welcome: https://github.com/peppekerstens/PowerShell.Management.Linux
    .Link
        https://learn.microsoft.com/powershell/module/microsoft.powershell.management/clear-recyclebin
    #>
    [CmdletBinding()]
    param()

    if ($IsLinux) {
        Write-Warning "Clear-RecycleBin is not yet implemented in PowerShell.Management.Linux. Contributions welcome: https://github.com/peppekerstens/PowerShell.Management.Linux"
        return
    }

    # Windows: delegate to built-in Microsoft.PowerShell.Management module
    Microsoft.PowerShell.Management\Clear-RecycleBin @PSBoundParameters
}
