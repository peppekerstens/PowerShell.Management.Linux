<#
.Synopsis
    Creates stub functions for PowerShell.Management.Linux.
    Each stub emits Write-Warning on Linux and delegates to
    Microsoft.PowerShell.Management\<CmdletName> on Windows.

    Run from the Helpers\ folder.
#>

$functionsPath = "$PSScriptRoot\..\PowerShell.Management.Linux\Functions"

# Cmdlets already fully implemented — skip these
$skip = @(
    'Get-Service.ps1',
    'Start-Service.ps1',
    'Stop-Service.ps1',
    'Restart-Service.ps1',
    'Get-ComputerInfo.ps1',
    'Rename-Computer.ps1',
    'Restart-Computer.ps1',
    'Stop-Computer.ps1'
)

# Cmdlets to generate stubs for (Windows-only or not yet implemented)
$stubs = @(
    'Resume-Service',
    'Suspend-Service',
    'Set-Service',
    'New-Service',
    'Remove-Service',
    'Get-HotFix',
    'Clear-RecycleBin'
)

foreach ($funcName in $stubs) {
    $filePath = Join-Path $functionsPath "$funcName.ps1"
    $content = @"
function $funcName {
    <#
    .Synopsis
        Not yet implemented on Linux. Delegates to Microsoft.PowerShell.Management\$funcName on Windows.
    .Notes
        This is a compatibility stub. On Linux a Write-Warning is emitted.
        Contributions welcome: https://github.com/peppekerstens/PowerShell.Management.Linux
    .Link
        https://learn.microsoft.com/powershell/module/microsoft.powershell.management/$($funcName.ToLower())
    #>
    [CmdletBinding()]
    param()

    if (`$IsLinux) {
        Write-Warning "$funcName is not yet implemented in PowerShell.Management.Linux. Contributions welcome: https://github.com/peppekerstens/PowerShell.Management.Linux"
        return
    }

    # Windows: delegate to built-in Microsoft.PowerShell.Management module
    Microsoft.PowerShell.Management\$funcName @PSBoundParameters
}
"@
    Set-Content -Path $filePath -Value $content -Encoding UTF8
    Write-Host "CREATED stub: $funcName.ps1"
}

Write-Host "`nDone."
