function Get-ComputerInfo {
    <#
    .Synopsis
        Gets a consolidated object of system and operating system properties.
    .Description
        Cross-platform implementation of Get-ComputerInfo.
        On Windows, delegates to the built-in Microsoft.PowerShell.Management\Get-ComputerInfo.
        On Linux, assembles OS and hardware information from /etc/os-release, /proc/cpuinfo,
        /proc/meminfo, uname, and hostnamectl.
    .Parameter Property
        The property names to retrieve. Wildcards supported.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/microsoft.powershell.management/get-computerinfo
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [string[]]$Property
    )

    if (-not $IsLinux) {
        Microsoft.PowerShell.Management\Get-ComputerInfo @PSBoundParameters
        return
    }

    # --- Gather info from various Linux sources ---

    # /etc/os-release
    $osRelease = @{}
    if (Test-Path '/etc/os-release') {
        Get-Content '/etc/os-release' | ForEach-Object {
            if ($_ -match '^([^=]+)=(.*)$') {
                $osRelease[$Matches[1]] = $Matches[2].Trim('"')
            }
        }
    }

    # uname
    $kernelName    = (uname -s 2>$null).Trim()
    $kernelRelease = (uname -r 2>$null).Trim()
    $kernelVersion = (uname -v 2>$null).Trim()
    $machine       = (uname -m 2>$null).Trim()
    $nodeName      = (uname -n 2>$null).Trim()

    # /proc/meminfo
    $totalMemBytes = 0
    $freeMemBytes  = 0
    if (Test-Path '/proc/meminfo') {
        Get-Content '/proc/meminfo' | ForEach-Object {
            if ($_ -match '^MemTotal:\s+(\d+)\s+kB') { $totalMemBytes = [uint64]$Matches[1] * 1024 }
            if ($_ -match '^MemAvailable:\s+(\d+)\s+kB') { $freeMemBytes  = [uint64]$Matches[1] * 1024 }
        }
    }

    # /proc/cpuinfo
    $processorName  = ''
    $processorCount = 0
    if (Test-Path '/proc/cpuinfo') {
        $cpuLines = Get-Content '/proc/cpuinfo'
        $processorName  = ($cpuLines | Where-Object { $_ -match '^model name' } | Select-Object -First 1) -replace '^model name\s*:\s*', ''
        $processorCount = ($cpuLines | Where-Object { $_ -match '^processor\s*:' }).Count
    }

    # hostnamectl (optional, systemd only)
    $chassis = 'Unknown'
    $hostCtlOutput = hostnamectl 2>$null
    if ($hostCtlOutput) {
        $chassisLine = $hostCtlOutput | Where-Object { $_ -match 'Chassis:' }
        if ($chassisLine) { $chassis = ($chassisLine -replace '.*Chassis:\s*', '').Trim() }
    }

    # Boot time from /proc/uptime or who -b
    $bootTime = $null
    try {
        $uptimeSeconds = [double]((Get-Content '/proc/uptime' -ErrorAction SilentlyContinue) -split '\s+')[0]
        $bootTime = (Get-Date).AddSeconds(-$uptimeSeconds)
    } catch {}

    $info = [PSCustomObject]@{
        # OS info
        OsName                  = $osRelease['PRETTY_NAME']
        OsType                  = $kernelName
        OsVersion               = $kernelRelease
        OsBuildNumber           = $kernelVersion
        OsArchitecture          = $machine
        OsLocale                = $env:LANG
        CsName                  = $nodeName
        CsDNSHostName           = $nodeName
        CsDomain                = ''
        CsWorkgroup             = ''
        # Hardware
        CsNumberOfProcessors    = $processorCount
        CsProcessors            = $processorName
        CsTotalPhysicalMemory   = $totalMemBytes
        OsFreePhysicalMemory    = $freeMemBytes
        CsSystemType            = $machine
        CsChassisType           = @($chassis)
        # Dates
        OsLastBootUpTime        = $bootTime
        OsInstallDate           = $null
        # Distro specifics
        OsDistribution          = $osRelease['NAME']
        OsDistributionVersion   = $osRelease['VERSION_ID']
        OsDistributionID        = $osRelease['ID']
        # PS compatibility props
        WindowsCurrentVersion   = $null
        WindowsEditionId        = $null
        WindowsInstallationType = $null
        WindowsProductName      = $osRelease['PRETTY_NAME']
        WindowsVersion          = $null
    }

    if ($PSBoundParameters.ContainsKey('Property')) {
        $selected = [ordered]@{}
        foreach ($prop in $Property) {
            $info.PSObject.Properties |
                Where-Object { $_.Name -like $prop } |
                ForEach-Object { $selected[$_.Name] = $_.Value }
        }
        [PSCustomObject]$selected
    } else {
        $info
    }
}
