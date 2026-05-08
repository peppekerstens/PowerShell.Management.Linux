<#
.Synopsis
    Groups services by their start type (Automatic, Manual, Disabled).
.Description
    Retrieves all services and presents a count per start type, followed by a detailed
    list of each group. Useful for auditing which services start automatically.
    Works identically on Windows (via Microsoft.PowerShell.Management) and Linux (via PowerShell.Management.Linux).
.Example
    .\Get-ServicesByStartType.ps1
.Notes
    Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
    Author: Peppe Kerstens (NLD)
    Requires: PowerShell.Management.Linux (Linux) or Microsoft.PowerShell.Management (Windows)
#>

#Requires -Modules PowerShell.Management.Linux

$services = Get-Service

Write-Host "=== Service Count by Start Type ===" -ForegroundColor Cyan
$services |
    Group-Object -Property StartType |
    Select-Object -Property Count, Name |
    Sort-Object -Property Count -Descending |
    Format-Table -AutoSize

Write-Host "=== Automatic Services ===" -ForegroundColor Cyan
$services |
    Where-Object { $_.StartType -eq 'Automatic' } |
    Select-Object -Property Name, DisplayName, Status |
    Sort-Object -Property Name |
    Format-Table -AutoSize
