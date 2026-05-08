#
# Module manifest for module 'PowerShell.Management.Linux'
#

@{
    RootModule        = 'PowerShell.Management.Linux.psm1'
    ModuleVersion     = '0.2.0'
    GUID              = 'c3d4e5f6-a7b8-9012-cdef-123456789012'
    Author            = 'Peppe Kerstens'
    CompanyName       = ''
    Copyright         = '(c) Peppe Kerstens. GPL-3.0 license.'
    Description       = 'PowerShell module for Linux providing cmdlet parity with Microsoft.PowerShell.Management. Implements Get-Service, Start-Service, Stop-Service, Restart-Service, Get-ComputerInfo, Rename-Computer, Restart-Computer and Stop-Computer using systemctl, hostnamectl, and shutdown.'
    PowerShellVersion = '7.2'
    RequiredModules   = @()

    FunctionsToExport = @(
        # Fully implemented
        'Get-Service',
        'Start-Service',
        'Stop-Service',
        'Restart-Service',
        'Get-ComputerInfo',
        'Rename-Computer',
        'Restart-Computer',
        'Stop-Computer',
        # Stubs (not-implemented on Linux)
        'Resume-Service',
        'Suspend-Service',
        'Set-Service',
        'New-Service',
        'Remove-Service',
        'Get-HotFix',
        'Clear-RecycleBin'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags         = @('Linux', 'Service', 'systemctl', 'ComputerInfo', 'CrossPlatform', 'Management')
            LicenseUri   = 'https://github.com/peppekerstens/PowerShell.Management.Linux/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/peppekerstens/PowerShell.Management.Linux'
            ReleaseNotes = @'
0.1.0 - Initial release. Get-Service, Start-Service, Stop-Service, Restart-Service (systemctl), Get-ComputerInfo, Rename-Computer, Restart-Computer, Stop-Computer. Stubs for Resume-Service, Suspend-Service, Set-Service, New-Service, Remove-Service, Get-HotFix, Clear-RecycleBin.
'@
        }
    }
}
