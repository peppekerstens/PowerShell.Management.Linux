<#
.Synopsis
    Finds services that are in a Failed or unexpected Stopped state.
.Description
    Checks all enabled (Automatic start) services and reports any that are not Running.
    Outputs a table of potentially problematic services with their status and start type.
    Works identically on Windows (via Microsoft.PowerShell.Management) and Linux (via PowerShell.Management.Linux).
.Example
    .\Get-FailedServices.ps1
.Notes
    Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
    Author: Peppe Kerstens (NLD)
    Requires: PowerShell.Management.Linux (Linux) or Microsoft.PowerShell.Management (Windows)
#>

#Requires -Modules PowerShell.Management.Linux

$problem = Get-Service |
    Where-Object { $_.Status -eq 'Failed' -or
                   ($_.StartType -eq 'Automatic' -and $_.Status -ne 'Running') }

if ($problem) {
    Write-Host "Services requiring attention:" -ForegroundColor Yellow
    $problem |
        Select-Object -Property Name, DisplayName, Status, StartType |
        Format-Table -AutoSize
} else {
    Write-Host "All Automatic services are running." -ForegroundColor Green
}
