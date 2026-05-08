function New-Service {
    <#
    .Synopsis
        Not yet implemented on Linux. Delegates to Microsoft.PowerShell.Management\New-Service on Windows.
    .Notes
        This is a compatibility stub. On Linux a Write-Warning is emitted.
        Contributions welcome: https://github.com/peppekerstens/PowerShell.Management.Linux
    .Link
        https://learn.microsoft.com/powershell/module/microsoft.powershell.management/new-service
    #>
    [CmdletBinding()]
    param()

    if ($IsLinux) {
        Write-Warning "New-Service is not yet implemented in PowerShell.Management.Linux. Contributions welcome: https://github.com/peppekerstens/PowerShell.Management.Linux"
        return
    }

    # Windows: delegate to built-in Microsoft.PowerShell.Management module
    Microsoft.PowerShell.Management\New-Service @PSBoundParameters
}
