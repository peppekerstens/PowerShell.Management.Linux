#Requires -Modules Pester

<#
.Synopsis
    Pester tests for PowerShell.Management.Linux.
    Tests run on Linux only (skipped on Windows).
#>

BeforeAll {
    $modulePath = "$PSScriptRoot\PowerShell.Management.Linux.psd1"
    Import-Module $modulePath -Force
}

Describe 'Get-Service' -Skip:(-not $IsLinux) {
    It 'Returns service objects' {
        $services = Get-Service
        $services | Should -Not -BeNullOrEmpty
    }

    It 'Returns objects with expected properties' {
        $svc = Get-Service | Select-Object -First 1
        $svc.PSObject.Properties.Name | Should -Contain 'Name'
        $svc.PSObject.Properties.Name | Should -Contain 'DisplayName'
        $svc.PSObject.Properties.Name | Should -Contain 'Status'
        $svc.PSObject.Properties.Name | Should -Contain 'StartType'
    }

    It 'Filters by Name' {
        $svc = Get-Service -Name 'ssh*'
        $svc | ForEach-Object { $_.Name | Should -BeLike 'ssh*' }
    }

    It 'Returns nothing for a non-existent service name' {
        $result = Get-Service -Name 'this-service-should-not-exist-xyz'
        $result | Should -BeNullOrEmpty
    }

    It 'Status is a known value' {
        $knownStatuses = @('Running', 'Stopped', 'StartPending', 'StopPending', 'Unknown')
        $services = Get-Service | Select-Object -First 5
        $services | ForEach-Object {
            $_.Status | Should -BeIn $knownStatuses
        }
    }
}

Describe 'Start-Service / Stop-Service / Restart-Service (command availability)' -Skip:(-not $IsLinux) {
    It 'Start-Service is available as a command' {
        Get-Command Start-Service | Should -Not -BeNullOrEmpty
    }

    It 'Stop-Service is available as a command' {
        Get-Command Stop-Service | Should -Not -BeNullOrEmpty
    }

    It 'Restart-Service is available as a command' {
        Get-Command Restart-Service | Should -Not -BeNullOrEmpty
    }

    It 'Start-Service supports -WhatIf' {
        { Start-Service -Name 'ssh' -WhatIf } | Should -Not -Throw
    }

    It 'Stop-Service supports -WhatIf' {
        { Stop-Service -Name 'ssh' -WhatIf } | Should -Not -Throw
    }
}

Describe 'Get-ComputerInfo' -Skip:(-not $IsLinux) {
    It 'Returns a single object' {
        $info = Get-ComputerInfo
        $info | Should -Not -BeNullOrEmpty
        ($info | Measure-Object).Count | Should -Be 1
    }

    It 'Has expected properties' {
        $info = Get-ComputerInfo
        $info.PSObject.Properties.Name | Should -Contain 'OsName'
        $info.PSObject.Properties.Name | Should -Contain 'CsName'
        $info.PSObject.Properties.Name | Should -Contain 'OsArchitecture'
        $info.PSObject.Properties.Name | Should -Contain 'CsTotalPhysicalMemory'
    }

    It 'CsName matches hostname' {
        $info = Get-ComputerInfo
        $info.CsName | Should -Be (hostname)
    }

    It 'Supports -Property filter' {
        $info = Get-ComputerInfo -Property 'OsName', 'CsName'
        $info.PSObject.Properties.Count | Should -Be 2
    }
}

Describe 'Rename-Computer (WhatIf only)' -Skip:(-not $IsLinux) {
    It 'Supports -WhatIf without error' {
        { Rename-Computer -NewName 'test-hostname' -WhatIf } | Should -Not -Throw
    }
}

Describe 'Restart-Computer (WhatIf only)' -Skip:(-not $IsLinux) {
    It 'Supports -WhatIf without error' {
        { Restart-Computer -WhatIf } | Should -Not -Throw
    }
}

Describe 'Stop-Computer (WhatIf only)' -Skip:(-not $IsLinux) {
    It 'Supports -WhatIf without error' {
        { Stop-Computer -WhatIf } | Should -Not -Throw
    }
}

Describe 'Stub cmdlets emit warning on Linux' -Skip:(-not $IsLinux) {
    It 'Resume-Service emits a warning' {
        Resume-Service 3>&1 | Should -Match 'not yet implemented'
    }

    It 'Suspend-Service emits a warning' {
        Suspend-Service 3>&1 | Should -Match 'not yet implemented'
    }

    It 'Get-HotFix emits a warning' {
        Get-HotFix 3>&1 | Should -Match 'not yet implemented'
    }

    It 'Clear-RecycleBin emits a warning' {
        Clear-RecycleBin 3>&1 | Should -Match 'not yet implemented'
    }
}
