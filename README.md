# PowerShell.Management.Linux

PowerShell 7.x module providing cmdlet parity with `Microsoft.PowerShell.Management` on Linux. Implements service management, computer information and computer control cmdlets that are missing or non-functional on Linux.

Part of the **Linux PowerShell Cmdlet Parity** project — inspired by Evgenij Smirnov's [2025 European PowerShell Summit session](https://www.youtube.com/watch?v=RlzinWYIjBY) and documented in the blog series at [peppekerstens.github.io](https://peppekerstens.github.io/linux-command-wrapping-part-1/).

---

## What it does

On **Linux**, wraps native CLI tools (`systemctl`, `hostnamectl`, `shutdown`, `/proc`, `/etc/os-release`) to provide PowerShell cmdlets matching the Windows `Microsoft.PowerShell.Management` API as closely as possible.

On **Windows**, every function delegates transparently to the built-in `Microsoft.PowerShell.Management` cmdlet — no behavioral change.

> Note: 46 of the 60 cmdlets in `Microsoft.PowerShell.Management` (filesystem, process, timezone, etc.) already work natively in PowerShell 7 on Linux and are not included here. This module covers only the genuine gap.

---

## Requirements

- PowerShell 7.2+
- **Linux only** — the module refuses to load on Windows (throws a descriptive error)
- Linux with `systemd` (`systemctl`, `hostnamectl`) — Ubuntu 20.04+, Debian 11+, etc.
- Root / `sudo` required for `Rename-Computer`, `Restart-Computer`, `Stop-Computer`

---

## Installation

```powershell
# Clone or copy the module folder to a PSModulePath location, then:
Import-Module PowerShell.Management.Linux
```

---

## Usage

```powershell
# List all running services
Get-Service | Where-Object Status -eq Running

# Filter by name (wildcard supported)
Get-Service -Name 'ssh*'

# Restart a service and return the updated object
Restart-Service -Name ssh -PassThru

# Get system information
Get-ComputerInfo

# Get specific properties only
Get-ComputerInfo -Property OsName, CsTotalPhysicalMemory

# Rename the host (requires root)
Rename-Computer -NewName myserver -Force

# Shut down immediately (requires root)
Stop-Computer
```

---

## Cmdlet Status

Legend: ✅ Implemented &nbsp;|&nbsp; ⚠️ Stub &nbsp;|&nbsp; ➖ N/A on Linux

| Cmdlet | Status | Linux tool | Notes |
|---|:---:|---|---|
| `Get-Service` | ✅ | `systemctl list-units` + `list-unit-files` | Name, DisplayName, Status, StartType, CanStop, CanPauseAndContinue; `-Name`, `-DisplayName`, `-Include`, `-Exclude` filters |
| `Start-Service` | ✅ | `systemctl start` | Pipeline input; `-PassThru`, `-WhatIf`, `-Confirm` |
| `Stop-Service` | ✅ | `systemctl stop` | Pipeline input; `-PassThru`, `-Force`, `-WhatIf`, `-Confirm` |
| `Restart-Service` | ✅ | `systemctl restart` | Pipeline input; `-PassThru`, `-Force`, `-WhatIf`, `-Confirm` |
| `Get-ComputerInfo` | ✅ | `/etc/os-release`, `/proc/cpuinfo`, `/proc/meminfo`, `uname`, `hostnamectl`, `/proc/uptime` | `-Property` filter supported |
| `Rename-Computer` | ✅ | `hostnamectl set-hostname` | Requires root; `-Force`, `-PassThru`, `-WhatIf`, `-Confirm` |
| `Restart-Computer` | ✅ | `shutdown -r` | Requires root; `-Delay` (minutes, default 0) |
| `Stop-Computer` | ✅ | `shutdown -h` | Requires root; `-Delay` (minutes, default 0) |
| `Resume-Service` | ⚠️ | Stub | No general Linux equivalent for paused services |
| `Suspend-Service` | ⚠️ | Stub | No general Linux equivalent |
| `Set-Service` | ⚠️ | Stub | Future: `systemctl enable`/`disable` |
| `New-Service` | ⚠️ | Stub | Future: systemd unit file creation |
| `Remove-Service` | ⚠️ | Stub | Future: systemd unit file removal |
| `Get-HotFix` | ⚠️ | Stub | Windows-specific concept |
| `Clear-RecycleBin` | ⚠️ | Stub | Windows-specific concept |

### Not included (already work natively in PS7 on Linux)

`Get-Process`, `Stop-Process`, `Start-Process`, `Wait-Process`, `Get-TimeZone`, `Set-TimeZone`, `Get-ChildItem`, `Get-Item`, `Set-Item`, `Copy-Item`, `Move-Item`, `Remove-Item`, `Get-Content`, `Set-Content`, `Add-Content`, `Clear-Content`, `Get-Location`, `Set-Location`, `Push-Location`, `Pop-Location`, `Test-Path`, `Resolve-Path`, `Convert-Path`, `Join-Path`, `Split-Path`, `Get-PSDrive`, `New-PSDrive`, `Remove-PSDrive`, `Get-PSProvider`, `Get-ItemProperty`, `Set-ItemProperty`, `New-ItemProperty`, `Remove-ItemProperty`, `Clear-ItemProperty`, `Rename-Item`, `Rename-ItemProperty`, `New-Item`, `Invoke-Item`, `Get-Clipboard`, `Set-Clipboard`, `Test-Connection`, `Debug-Process`.

---

## Implementation notes

- `Get-Service` joins output from `systemctl list-units` (running state) and `systemctl list-unit-files` (start type) on service name (`.service` suffix stripped).
- Status mapping: `active` → `Running`, `inactive` → `Stopped`, `failed` → `Failed`.
- StartType mapping: `enabled` → `Automatic`, `disabled` → `Disabled`, `static` → `Manual`.
- `Get-ComputerInfo` assembles a single `PSCustomObject` from multiple `/proc` and system files; `-Property` filters which properties are populated, skipping unnecessary reads.
- `Rename-Computer` checks `id -u` for root before calling `hostnamectl`.

---

## Version history

| Version | Notes |
|---|---|
| 0.2.0 | Linux-only guard added (throws on Windows). `Get-ComputerInfo` gains `CsNumberOfLogicalProcessors` and `OsUptime` properties; `-Property` filter fixed. Tests rewritten for Pester 5.2+: 60/60 pass on WSL2, 0 skipped on Linux. |
| 0.1.0 | Initial release. `Get-Service`, `Start-Service`, `Stop-Service`, `Restart-Service`, `Get-ComputerInfo`, `Rename-Computer`, `Restart-Computer`, `Stop-Computer` implemented. Stubs for `Resume-Service`, `Suspend-Service`, `Set-Service`, `New-Service`, `Remove-Service`, `Get-HotFix`, `Clear-RecycleBin`. |

---

## License

GPL-3.0 — see [LICENSE](LICENSE).
