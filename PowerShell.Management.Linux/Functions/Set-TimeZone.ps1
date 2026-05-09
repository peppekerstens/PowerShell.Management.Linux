function Set-TimeZone {
    <#
    .SYNOPSIS
        Sets the system time zone. On Linux, uses 'sudo timedatectl set-timezone'.
    .DESCRIPTION
        Requires sudo privileges. If sudo is not available or the operation fails,
        an error is written.
    .PARAMETER Id
        The IANA time zone identifier (e.g. 'Europe/Amsterdam', 'UTC', 'America/New_York').
        Use 'Get-TimeZone -ListAvailable' or 'timedatectl list-timezones' to see valid values.
    .PARAMETER Name
        Alias for -Id for compatibility with some usage patterns. Same as -Id.
    .PARAMETER PassThru
        When specified, returns the new time zone object.
    .LINK
        https://learn.microsoft.com/powershell/module/microsoft.powershell.management/set-timezone
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([System.TimeZoneInfo])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = 'Id')]
        [string]$Id,

        [Parameter(Mandatory = $true, ParameterSetName = 'Name')]
        [string]$Name,

        [Parameter()]
        [switch]$PassThru
    )
    process {
        if ($IsLinux) {
            $tzId = if ($PSCmdlet.ParameterSetName -eq 'Name') { $Name } else { $Id }

            if ($PSCmdlet.ShouldProcess($tzId, 'Set system time zone')) {
                $result = & sudo timedatectl set-timezone $tzId 2>&1
                if ($LASTEXITCODE -ne 0) {
                    Write-Error "Set-TimeZone: timedatectl set-timezone failed: $result"
                    return
                }
                if ($PassThru) {
                    [System.TimeZoneInfo]::FindSystemTimeZoneById($tzId)
                }
            }
        } else {
            Microsoft.PowerShell.Management\Set-TimeZone @PSBoundParameters
        }
    }
}
