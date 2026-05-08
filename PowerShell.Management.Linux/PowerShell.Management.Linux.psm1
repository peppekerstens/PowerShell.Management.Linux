#Requires -Version 7.2

# PowerShell.Management.Linux.psm1
# Root module for PowerShell.Management.Linux.
# Dot-sources all function files from the Functions\ subdirectory.

$functionPath = Join-Path $PSScriptRoot 'Functions'
$functionFiles = Get-ChildItem -Path $functionPath -Filter '*.ps1' -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -notlike '*.Tests.ps1' }
foreach ($file in $functionFiles) {
    . $file.FullName
}
