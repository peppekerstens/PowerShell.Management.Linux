#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }
<#
.Synopsis
    Pester tests for PowerShell.Management.Linux example scripts.
.Description
    Validates that each example script in the Examples\ folder:
      - exists on disk
      - has no syntax errors (parses cleanly)
    Linux-only execution tests are guarded with -Skip:(-not $IsLinux).
    All tests run on Windows (syntax/structure checks); live execution
    tests are skipped on Windows.
.Notes
    Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
    Author: Peppe Kerstens (NLD)
    Run with: Invoke-Pester .\Examples.Tests.ps1 -Output Detailed
#>

# $PSScriptRoot can be $null at discovery time in Pester 5.3.x when the file
# is passed via PesterConfiguration; resolve via $PSCommandPath as a fallback.
BeforeDiscovery {
    $script:ExamplesDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path $PSCommandPath -Parent }
    $script:ExampleFiles = @(
        'Get-ServiceStatus.ps1'
        'Get-SystemInfo.ps1'
        'Get-FailedServices.ps1'
        'Get-ServicesByStartType.ps1'
        'Get-SystemHealthReport.ps1'
    )
}

BeforeAll {
    $script:ExamplesDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path $PSCommandPath -Parent }
    if ($IsLinux) {
        $modulePath = Join-Path (Split-Path $script:ExamplesDir -Parent) 'PowerShell.Management.Linux' 'PowerShell.Management.Linux.psd1'
        if (Test-Path $modulePath) {
            Import-Module $modulePath -Force -ErrorAction Stop
        }
    }
}

Describe 'Example script files exist' {
    It 'Examples directory contains <_>' -ForEach $script:ExampleFiles {
        Join-Path $script:ExamplesDir $_ | Should -Exist
    }
}

Describe 'Example scripts have no syntax errors' {
    It '<_> parses without errors' -ForEach $script:ExampleFiles {
        $filePath = Join-Path $script:ExamplesDir $_
        $errors   = $null
        $null = [System.Management.Automation.Language.Parser]::ParseFile($filePath, [ref]$null, [ref]$errors)
        $errors | Should -BeNullOrEmpty
    }
}

# ---------------------------------------------------------------------------
# Get-ServiceStatus
# ---------------------------------------------------------------------------

Describe 'Get-ServiceStatus' {
    It 'script file exists' {
        Join-Path $script:ExamplesDir 'Get-ServiceStatus.ps1' | Should -Exist
    }

    It 'Get-Service returns objects with required properties' -Skip:(-not $IsLinux) {
        $result = Get-Service
        $result | Should -Not -BeNullOrEmpty
        $result[0].PSObject.Properties.Name | Should -Contain 'Name'
        $result[0].PSObject.Properties.Name | Should -Contain 'Status'
        $result[0].PSObject.Properties.Name | Should -Contain 'StartType'
    }

    It 'Get-Service Status values are from known set' -Skip:(-not $IsLinux) {
        $knownStatuses = @('Running', 'Stopped', 'StartPending', 'StopPending', 'Failed', 'Unknown')
        Get-Service | Select-Object -First 20 | ForEach-Object {
            $_.Status | Should -BeIn $knownStatuses
        }
    }

    It 'Group-Object on Status produces at least one group' -Skip:(-not $IsLinux) {
        $groups = Get-Service | Group-Object -Property Status
        $groups | Should -Not -BeNullOrEmpty
        $groups[0].Count | Should -BeGreaterThan 0
    }
}

# ---------------------------------------------------------------------------
# Get-SystemInfo
# ---------------------------------------------------------------------------

Describe 'Get-SystemInfo' {
    It 'script file exists' {
        Join-Path $script:ExamplesDir 'Get-SystemInfo.ps1' | Should -Exist
    }

    It 'Get-ComputerInfo returns exactly one object' -Skip:(-not $IsLinux) {
        (Get-ComputerInfo | Measure-Object).Count | Should -Be 1
    }

    It 'CsTotalPhysicalMemory is greater than 0' -Skip:(-not $IsLinux) {
        (Get-ComputerInfo).CsTotalPhysicalMemory | Should -BeGreaterThan 0
    }

    It 'CsName matches hostname' -Skip:(-not $IsLinux) {
        (Get-ComputerInfo).CsName | Should -Be (hostname)
    }

    It 'OsUptime is a positive TimeSpan' -Skip:(-not $IsLinux) {
        $uptime = (Get-ComputerInfo).OsUptime
        $uptime | Should -Not -BeNullOrEmpty
        $uptime.TotalSeconds | Should -BeGreaterThan 0
    }

    It 'CsNumberOfLogicalProcessors is at least 1' -Skip:(-not $IsLinux) {
        (Get-ComputerInfo).CsNumberOfLogicalProcessors | Should -BeGreaterOrEqual 1
    }
}

# ---------------------------------------------------------------------------
# Get-FailedServices
# ---------------------------------------------------------------------------

Describe 'Get-FailedServices' {
    It 'script file exists' {
        Join-Path $script:ExamplesDir 'Get-FailedServices.ps1' | Should -Exist
    }

    It 'failed service filter returns only Failed or stopped-Automatic services' -Skip:(-not $IsLinux) {
        $problem = Get-Service |
            Where-Object { $_.Status -eq 'Failed' -or
                           ($_.StartType -eq 'Automatic' -and $_.Status -ne 'Running') }
        # Result can be empty (healthy system) or non-empty — just verify types
        $problem | ForEach-Object {
            ($_.Status -eq 'Failed' -or ($_.StartType -eq 'Automatic' -and $_.Status -ne 'Running')) |
                Should -Be $true
        }
    }
}

# ---------------------------------------------------------------------------
# Get-ServicesByStartType
# ---------------------------------------------------------------------------

Describe 'Get-ServicesByStartType' {
    It 'script file exists' {
        Join-Path $script:ExamplesDir 'Get-ServicesByStartType.ps1' | Should -Exist
    }

    It 'StartType values are from known set' -Skip:(-not $IsLinux) {
        $knownTypes = @('Automatic', 'Manual', 'Disabled', 'Unknown')
        Get-Service | ForEach-Object {
            $_.StartType | Should -BeIn $knownTypes
        }
    }

    It 'there is at least one Automatic service' -Skip:(-not $IsLinux) {
        $auto = Get-Service | Where-Object { $_.StartType -eq 'Automatic' }
        $auto | Should -Not -BeNullOrEmpty
    }
}

# ---------------------------------------------------------------------------
# Get-SystemHealthReport
# ---------------------------------------------------------------------------

Describe 'Get-SystemHealthReport' {
    It 'script file exists' {
        Join-Path $script:ExamplesDir 'Get-SystemHealthReport.ps1' | Should -Exist
    }

    It 'memory utilisation percentage is between 0 and 100' -Skip:(-not $IsLinux) {
        $info    = Get-ComputerInfo
        $totalGB = $info.CsTotalPhysicalMemory / 1GB
        $freeGB  = $info.OsFreePhysicalMemory  / 1GB
        $pct     = if ($totalGB -gt 0) { (($totalGB - $freeGB) / $totalGB) * 100 } else { 0 }
        $pct | Should -BeGreaterOrEqual 0
        $pct | Should -BeLessOrEqual 100
    }

    It 'Running service count is positive' -Skip:(-not $IsLinux) {
        $running = (Get-Service | Where-Object Status -eq 'Running').Count
        $running | Should -BeGreaterThan 0
    }

    It 'total service count equals sum of Running, Stopped and other statuses' -Skip:(-not $IsLinux) {
        $all     = Get-Service
        $grouped = $all | Group-Object -Property Status
        $sumFromGroups = ($grouped | Measure-Object -Property Count -Sum).Sum
        $sumFromGroups | Should -Be $all.Count
    }
}

Describe 'Scenario: Service install/start/stop/remove lifecycle' -Skip:(-not $IsLinux) {
    BeforeAll {
        $modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'PowerShell.Management.Linux' 'PowerShell.Management.Linux.psd1'
        Import-Module $modulePath -Force -ErrorAction Stop
        $script:svcName = 'pester-test-svc'
    }
    AfterAll {
        # Best-effort cleanup
        & systemctl stop    $script:svcName 2>$null
        & systemctl disable $script:svcName 2>$null
        Remove-Service -Name $script:svcName -ErrorAction SilentlyContinue
        Remove-Module 'PowerShell.Management.Linux' -Force -ErrorAction SilentlyContinue
    }

    It 'New-Service creates a systemd unit for a simple oneshot' {
        { New-Service -Name $script:svcName -BinaryPathName '/bin/true' -Description 'Pester test service' } |
            Should -Not -Throw
        & systemctl cat $script:svcName 2>&1 | Should -Match 'ExecStart'
    }
    It 'Get-Service finds the new service' {
        $svc = Get-Service -Name $script:svcName
        $svc | Should -Not -BeNullOrEmpty
        $svc.Name | Should -Be $script:svcName
    }
    It 'Start-Service starts the service without error' {
        { Start-Service -Name $script:svcName } | Should -Not -Throw
    }
    It 'Stop-Service stops the service without error' {
        { Stop-Service -Name $script:svcName } | Should -Not -Throw
    }
    It 'Remove-Service removes the unit file' {
        { Remove-Service -Name $script:svcName } | Should -Not -Throw
        { Get-Service -Name $script:svcName -ErrorAction Stop } | Should -Throw
    }
}
