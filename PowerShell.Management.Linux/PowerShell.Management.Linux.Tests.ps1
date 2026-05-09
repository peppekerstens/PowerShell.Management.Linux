#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }

<#
.SYNOPSIS
    Pester tests for PowerShell.Management.Linux module.
.DESCRIPTION
    Tests module surface (function/alias counts), implemented cmdlet behaviour,
    and per-stub exported/no-throw/emits-warning checks.
    All tests require Linux — the module refuses to load on Windows by design.
    Describe blocks that require the module are skipped automatically on Windows.
    Run with: Invoke-Pester ./PowerShell.Management.Linux.Tests.ps1 -Output Detailed
#>

BeforeDiscovery {
    $script:OnLinux = $IsLinux

    $script:ExpectedFunctions = @(
        'Get-Service', 'Start-Service', 'Stop-Service', 'Restart-Service',
        'Get-ComputerInfo', 'Rename-Computer', 'Restart-Computer', 'Stop-Computer',
        'Resume-Service', 'Suspend-Service', 'Set-Service',
        'New-Service', 'Remove-Service', 'Set-TimeZone', 'Get-HotFix', 'Clear-RecycleBin'
    )

    $script:StubFunctions = @(
        'Resume-Service', 'Suspend-Service', 'Set-Service',
        'Get-HotFix', 'Clear-RecycleBin'
    )
}

BeforeAll {
    if ($IsLinux) {
        $ModulePath = Join-Path $PSScriptRoot 'PowerShell.Management.Linux.psd1'
        Import-Module $ModulePath -Force
    }
}

AfterAll {
    if ($IsLinux) {
        Remove-Module PowerShell.Management.Linux -ErrorAction SilentlyContinue
    }
}

# ---------------------------------------------------------------------------
# Module surface
# ---------------------------------------------------------------------------

Describe 'PowerShell.Management.Linux module surface' -Skip:(-not $script:OnLinux) {

    It 'exports exactly 16 functions' {
        (Get-Module PowerShell.Management.Linux).ExportedFunctions.Count | Should -Be 16
    }

    It 'exports 0 aliases' {
        (Get-Module PowerShell.Management.Linux).ExportedAliases.Count | Should -Be 0
    }

    It "exports function '<fn>'" -TestCases ($script:ExpectedFunctions | ForEach-Object { @{ fn = $_ } }) {
        (Get-Module PowerShell.Management.Linux).ExportedFunctions.Keys | Should -Contain $fn
    }
}

# ---------------------------------------------------------------------------
# Get-Service
# ---------------------------------------------------------------------------

Describe 'Get-Service' -Skip:(-not $IsLinux) {

    It 'returns service objects without error' {
        { Get-Service } | Should -Not -Throw
    }

    It 'returns objects with expected properties' {
        $svc = Get-Service | Select-Object -First 1
        $svc | Should -Not -BeNullOrEmpty
        $svc.PSObject.Properties.Name | Should -Contain 'Name'
        $svc.PSObject.Properties.Name | Should -Contain 'DisplayName'
        $svc.PSObject.Properties.Name | Should -Contain 'Status'
        $svc.PSObject.Properties.Name | Should -Contain 'StartType'
        $svc.PSObject.Properties.Name | Should -Contain 'CanStop'
        $svc.PSObject.Properties.Name | Should -Contain 'CanPauseAndContinue'
    }

    It 'Status is a known value' {
        $knownStatuses = @('Running', 'Stopped', 'StartPending', 'StopPending', 'Failed', 'Unknown')
        Get-Service | Select-Object -First 10 | ForEach-Object {
            $_.Status | Should -BeIn $knownStatuses
        }
    }

    It 'filters by -Name wildcard' {
        $result = Get-Service -Name 'ssh*'
        $result | ForEach-Object { $_.Name | Should -BeLike 'ssh*' }
    }

    It 'returns nothing for a non-existent service name' {
        Get-Service -Name 'this-service-does-not-exist-xyz' | Should -BeNullOrEmpty
    }
}

# ---------------------------------------------------------------------------
# Start-Service / Stop-Service / Restart-Service
# ---------------------------------------------------------------------------

Describe 'Start-Service' -Skip:(-not $IsLinux) {
    It 'is exported' {
        (Get-Module PowerShell.Management.Linux).ExportedFunctions.Keys | Should -Contain 'Start-Service'
    }
    It 'supports -WhatIf without error' {
        { Start-Service -Name 'ssh' -WhatIf } | Should -Not -Throw
    }
}

Describe 'Stop-Service' -Skip:(-not $IsLinux) {
    It 'is exported' {
        (Get-Module PowerShell.Management.Linux).ExportedFunctions.Keys | Should -Contain 'Stop-Service'
    }
    It 'supports -WhatIf without error' {
        { Stop-Service -Name 'ssh' -WhatIf } | Should -Not -Throw
    }
}

Describe 'Restart-Service' -Skip:(-not $IsLinux) {
    It 'is exported' {
        (Get-Module PowerShell.Management.Linux).ExportedFunctions.Keys | Should -Contain 'Restart-Service'
    }
    It 'supports -WhatIf without error' {
        { Restart-Service -Name 'ssh' -WhatIf } | Should -Not -Throw
    }
}

# ---------------------------------------------------------------------------
# Get-ComputerInfo
# ---------------------------------------------------------------------------

Describe 'Get-ComputerInfo' -Skip:(-not $IsLinux) {

    It 'returns exactly one object without error' {
        { Get-ComputerInfo } | Should -Not -Throw
        (Get-ComputerInfo | Measure-Object).Count | Should -Be 1
    }

    It 'has expected properties' {
        $info = Get-ComputerInfo
        $info.PSObject.Properties.Name | Should -Contain 'OsName'
        $info.PSObject.Properties.Name | Should -Contain 'OsVersion'
        $info.PSObject.Properties.Name | Should -Contain 'OsArchitecture'
        $info.PSObject.Properties.Name | Should -Contain 'CsName'
        $info.PSObject.Properties.Name | Should -Contain 'CsTotalPhysicalMemory'
        $info.PSObject.Properties.Name | Should -Contain 'CsNumberOfLogicalProcessors'
        $info.PSObject.Properties.Name | Should -Contain 'OsUptime'
    }

    It 'CsName matches hostname' {
        (Get-ComputerInfo).CsName | Should -Be (hostname)
    }

    It 'CsTotalPhysicalMemory is a positive number' {
        (Get-ComputerInfo).CsTotalPhysicalMemory | Should -BeGreaterThan 0
    }

    It 'supports -Property filter and returns only requested properties' {
        $info = Get-ComputerInfo -Property OsName, CsName
        ($info.PSObject.Properties | Measure-Object).Count | Should -Be 2
        $info.PSObject.Properties.Name | Should -Contain 'OsName'
        $info.PSObject.Properties.Name | Should -Contain 'CsName'
    }
}

# ---------------------------------------------------------------------------
# Rename-Computer / Restart-Computer / Stop-Computer
# ---------------------------------------------------------------------------

Describe 'Rename-Computer' -Skip:(-not $IsLinux) {
    It 'is exported' {
        (Get-Module PowerShell.Management.Linux).ExportedFunctions.Keys | Should -Contain 'Rename-Computer'
    }
    It 'supports -WhatIf without error' {
        { Rename-Computer -NewName 'test-hostname' -WhatIf } | Should -Not -Throw
    }
}

Describe 'Restart-Computer' -Skip:(-not $IsLinux) {
    It 'is exported' {
        (Get-Module PowerShell.Management.Linux).ExportedFunctions.Keys | Should -Contain 'Restart-Computer'
    }
    It 'supports -WhatIf without error' {
        { Restart-Computer -WhatIf } | Should -Not -Throw
    }
}

Describe 'Stop-Computer' -Skip:(-not $IsLinux) {
    It 'is exported' {
        (Get-Module PowerShell.Management.Linux).ExportedFunctions.Keys | Should -Contain 'Stop-Computer'
    }
    It 'supports -WhatIf without error' {
        { Stop-Computer -WhatIf } | Should -Not -Throw
    }
}

# ---------------------------------------------------------------------------
# Stub functions — per-stub: exported, no-throw, emits-warning
# ---------------------------------------------------------------------------

Describe 'Stub functions' -Skip:(-not $script:OnLinux) {

    It "'<fn>' is exported" -TestCases ($script:StubFunctions | ForEach-Object { @{ fn = $_ } }) {
        (Get-Module PowerShell.Management.Linux).ExportedFunctions.Keys | Should -Contain $fn
    }

    It "'<fn>' does not throw on Linux" -TestCases ($script:StubFunctions | ForEach-Object { @{ fn = $_ } }) {
        { & $fn } | Should -Not -Throw
    }

    It "'<fn>' emits a warning on Linux" -TestCases ($script:StubFunctions | ForEach-Object { @{ fn = $_ } }) {
        $warnings = & { & $fn } 3>&1 | Where-Object { $_ -is [System.Management.Automation.WarningRecord] }
        $warnings | Should -Not -BeNullOrEmpty
    }
}

# ---------------------------------------------------------------------------
Describe 'New-Service' -Skip:(-not $script:OnLinux) {

    It 'is exported' {
        (Get-Module PowerShell.Management.Linux).ExportedFunctions.Keys | Should -Contain 'New-Service'
    }

    It 'supports -WhatIf without error' {
        { New-Service -Name 'test-pester-svc' -BinaryPathName '/bin/true' -WhatIf } | Should -Not -Throw
    }
}

# ---------------------------------------------------------------------------
Describe 'Remove-Service' -Skip:(-not $script:OnLinux) {

    It 'is exported' {
        (Get-Module PowerShell.Management.Linux).ExportedFunctions.Keys | Should -Contain 'Remove-Service'
    }

    It 'supports -WhatIf without error' {
        { Remove-Service -Name 'test-pester-svc' -WhatIf } | Should -Not -Throw
    }
}

# ---------------------------------------------------------------------------
Describe 'Set-TimeZone' -Skip:(-not $script:OnLinux) {

    It 'is exported' {
        (Get-Module PowerShell.Management.Linux).ExportedFunctions.Keys | Should -Contain 'Set-TimeZone'
    }

    It 'supports -WhatIf without error' {
        { Set-TimeZone -Id 'UTC' -WhatIf } | Should -Not -Throw
    }
}
