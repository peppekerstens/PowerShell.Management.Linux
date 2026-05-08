<#
.Synopsis
    Displays a formatted system information summary.
.Description
    Retrieves key system properties via Get-ComputerInfo and presents them in a
    readable format: OS, kernel, architecture, memory, processor count, and uptime.
    Works identically on Windows (via Microsoft.PowerShell.Management) and Linux (via PowerShell.Management.Linux).
.Example
    .\Get-SystemInfo.ps1
.Notes
    Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
    Author: Peppe Kerstens (NLD)
    Requires: PowerShell.Management.Linux (Linux) or Microsoft.PowerShell.Management (Windows)
#>

#Requires -Modules PowerShell.Management.Linux

$info = Get-ComputerInfo

[PSCustomObject]@{
    Hostname          = $info.CsName
    OS                = $info.OsName
    KernelVersion     = $info.OsVersion
    Architecture      = $info.OsArchitecture
    MemoryGB          = [math]::Round($info.CsTotalPhysicalMemory / 1GB, 2)
    FreeMemoryGB      = [math]::Round($info.OsFreePhysicalMemory / 1GB, 2)
    LogicalProcessors = $info.CsNumberOfLogicalProcessors
    Uptime            = if ($info.OsUptime) { '{0}d {1}h {2}m' -f $info.OsUptime.Days, $info.OsUptime.Hours, $info.OsUptime.Minutes } else { 'N/A' }
} | Format-List
