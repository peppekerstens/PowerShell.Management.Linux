#Requires -Version 7.2

# PowerShell.Management.Linux.psm1
# Root module for PowerShell.Management.Linux.
# Dot-sources all function files from the Functions\ subdirectory.

# Linux-only guard — this module wraps Linux CLI tools (systemctl, hostnamectl,
# shutdown) and must not be loaded on Windows. On Windows, use the built-in module:
#   Import-Module Microsoft.PowerShell.Management
if (-not $IsLinux) {
    throw (
        "PowerShell.Management.Linux cannot be loaded on Windows. " +
        "On Windows, use the built-in 'Microsoft.PowerShell.Management' module.`n" +
        "PowerShell.Management.Linux is a Linux-only peer module that wraps systemctl and related tools."
    )
}

$functionPath = Join-Path $PSScriptRoot 'Functions'
$functionFiles = Get-ChildItem -Path $functionPath -Filter '*.ps1' -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notlike '*.Tests.ps1' }
foreach ($file in $functionFiles) {
    . $file.FullName
}
