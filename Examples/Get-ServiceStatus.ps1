<#
.Synopsis
    Lists all services grouped by their current status.
.Description
    Retrieves all system services and groups them by Status (Running, Stopped, Failed, etc.).
    Useful for a quick overview of service health across the system.
    Works identically on Windows (via Microsoft.PowerShell.Management) and Linux (via PowerShell.Management.Linux).
.Example
    .\Get-ServiceStatus.ps1
.Notes
    Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
    Author: Peppe Kerstens (NLD)
    Requires: PowerShell.Management.Linux (Linux) or Microsoft.PowerShell.Management (Windows)
#>

#Requires -Modules PowerShell.Management.Linux

Get-Service |
    Group-Object -Property Status |
    Select-Object -Property Count, Name |
    Sort-Object -Property Count -Descending |
    Format-Table -AutoSize
