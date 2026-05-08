<#
.Synopsis
    Produces a combined system health report: uptime, memory usage, and service health.
.Description
    Combines Get-ComputerInfo and Get-Service to produce a single-page health snapshot:
      - System uptime and memory utilisation
      - Count of Running / Stopped / Failed services
      - List of any failed services
    Works identically on Windows (via Microsoft.PowerShell.Management) and Linux (via PowerShell.Management.Linux).
.Example
    .\Get-SystemHealthReport.ps1
.Notes
    Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
    Author: Peppe Kerstens (NLD)
    Requires: PowerShell.Management.Linux (Linux) or Microsoft.PowerShell.Management (Windows)
#>

#Requires -Modules PowerShell.Management.Linux

$info     = Get-ComputerInfo
$services = Get-Service

$totalMemGB  = [math]::Round($info.CsTotalPhysicalMemory / 1GB, 2)
$freeMemGB   = [math]::Round($info.OsFreePhysicalMemory  / 1GB, 2)
$usedMemPct  = if ($totalMemGB -gt 0) { [math]::Round((($totalMemGB - $freeMemGB) / $totalMemGB) * 100, 1) } else { 0 }
$uptimeStr   = if ($info.OsUptime) { '{0}d {1}h {2}m' -f $info.OsUptime.Days, $info.OsUptime.Hours, $info.OsUptime.Minutes } else { 'N/A' }

$running = ($services | Where-Object Status -eq 'Running').Count
$stopped = ($services | Where-Object Status -eq 'Stopped').Count
$failed  = ($services | Where-Object Status -eq 'Failed').Count

Write-Host "=== System Health Report — $($info.CsName) ===" -ForegroundColor Cyan
Write-Host "OS       : $($info.OsName)"
Write-Host "Uptime   : $uptimeStr"
Write-Host "Memory   : $freeMemGB GB free / $totalMemGB GB total ($usedMemPct% used)"
Write-Host ""
Write-Host "=== Services ===" -ForegroundColor Cyan
Write-Host "Running  : $running"
Write-Host "Stopped  : $stopped"
Write-Host "Failed   : $failed"  -ForegroundColor $(if ($failed -gt 0) { 'Red' } else { 'Green' })

if ($failed -gt 0) {
    Write-Host ""
    Write-Host "Failed services:" -ForegroundColor Red
    $services |
        Where-Object { $_.Status -eq 'Failed' } |
        Select-Object -Property Name, DisplayName |
        Format-Table -AutoSize
}
