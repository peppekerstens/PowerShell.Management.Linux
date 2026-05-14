# PowerShell.Management.Linux

[![Pester Tests](https://github.com/peppekerstens/PowerShell.Management.Linux/actions/workflows/pester.yml/badge.svg)](https://github.com/peppekerstens/PowerShell.Management.Linux/actions/workflows/pester.yml)

PowerShell 7.x module providing cmdlet parity with `Microsoft.PowerShell.Management` on Linux. Implements service management, computer information and computer control cmdlets that are missing or non-functional on Linux.

Part of the **Linux PowerShell Cmdlet Parity** project — inspired by Evgenij Smirnov's [2025 European PowerShell Summit session](https://www.youtube.com/watch?v=RlzinWYIjBY) and documented in the blog series at [peppekerstens.github.io](https://peppekerstens.github.io/linux-command-wrapping-part-1/).

---

## What it does

On **Linux**, wraps native CLI tools (`systemctl`, `hostnamectl`, `shutdown`, `/proc`, `/etc/os-release`) to provide PowerShell cmdlets matching the Windows `Microsoft.PowerShell.Management` API as closely as possible.

> **Note:** 46 of the 60 cmdlets in `Microsoft.PowerShell.Management` (filesystem, process, timezone, etc.) already work natively in PowerShell 7 on Linux and are not included here. This module covers only the genuine gap.

---

## Requirements

- PowerShell 7.2+
- **Linux only** — the module refuses to load on Windows (throws a descriptive error)
- Linux with `systemd` (`systemctl`, `hostnamectl`) — Ubuntu 20.04+, Debian 11+, etc.
- Root / `sudo` required for `Rename-Computer`

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

**Note:** `Restart-Computer` and `Stop-Computer` are not included in this module — they are already native cross-platform cmdlets in PowerShell 7. See [Part 16](https://peppekerstens.github.io/the-list-was-a-year-old-linux-command-wrapping-part-16/) for details.

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

| `Resume-Service` | ⚠️ | Stub | No general Linux equivalent for paused services |
| `Suspend-Service` | ⚠️ | Stub | No general Linux equivalent |
| `Set-Service` | ⚠️ | Stub | Future: `systemctl enable`/`disable` |
| `New-Service` | ⚠️ | Stub | Future: systemd unit file creation |
| `Remove-Service` | ⚠️ | Stub | Future: systemd unit file removal |
| `Get-HotFix` | ⚠️ | Stub | Windows-specific concept |
| `Clear-RecycleBin` | ⚠️ | Stub | Windows-specific concept |

### Not included (already work natively in PS7 on Linux)

`Restart-Computer`, `Stop-Computer`, `Get-Process`, `Stop-Process`, `Start-Process`, `Wait-Process`, `Get-TimeZone`, `Set-TimeZone`, `Get-ChildItem`, `Get-Item`, `Set-Item`, `Copy-Item`, `Move-Item`, `Remove-Item`, `Get-Content`, `Set-Content`, `Add-Content`, `Clear-Content`, `Get-Location`, `Set-Location`, `Push-Location`, `Pop-Location`, `Test-Path`, `Resolve-Path`, `Convert-Path`, `Join-Path`, `Split-Path`, `Get-PSDrive`, `New-PSDrive`, `Remove-PSDrive`, `Get-PSProvider`, `Get-ItemProperty`, `Set-ItemProperty`, `New-ItemProperty`, `Remove-ItemProperty`, `Clear-ItemProperty`, `Rename-Item`, `Rename-ItemProperty`, `New-Item`, `Invoke-Item`, `Get-Clipboard`, `Set-Clipboard`, `Test-Connection`, `Debug-Process`.

---

## How we built this

The starting point was figuring out what is actually missing. The Windows `Microsoft.PowerShell.Management` module exports 60 cmdlets. Many of them — all the filesystem and path cmdlets, process management, timezone — are implemented in cross-platform .NET and work fine in PowerShell 7 on Linux already. Wrapping those would just shadow the built-in implementations, which could cause subtle breakage. So the first task was a careful audit.

After stripping out everything that already works, the gap is 13 cmdlets. Six get full implementations, seven become stubs.

### Service management: joining two systemctl outputs

`Get-Service` on Windows returns rich objects with `Status`, `StartType`, `DisplayName` and more. On Linux, `systemctl` spreads this information across two separate commands:

- `systemctl list-units --type=service --all --output=json` — tells you what is running right now (active/inactive/failed) with description
- `systemctl list-unit-files --type=service --output=json` — tells you what is enabled/disabled/static

Both commands support `--output=json` (systemd 240+), so no text splitting or column-width fragility. The implementation calls both, joins on the service name (stripping the `.service` suffix), maps the states, and returns a `PSCustomObject` with a shape matching `ServiceController` on Windows:

```powershell
$status    = 'active/running' → 'Running'
$startType = 'enabled'        → 'Automatic'
$startType = 'static'         → 'Manual'
$startType = 'disabled'       → 'Disabled'
```

A `HashSet` tracks which names appeared in `list-units`. Services that appear in `list-unit-files` but not in `list-units` (never started, or inactive) are added separately with `Status = 'Stopped'`. This ensures the output matches what Windows returns for similar services.

`Start-Service`, `Stop-Service` and `Restart-Service` are straightforward wrappers. They all support `-PassThru` (calls `Get-Service` after the operation and returns the updated object) and `SupportsShouldProcess` for `-WhatIf`/`-Confirm`.

### Get-ComputerInfo: assembling from /proc

On Windows, `Get-ComputerInfo` pulls everything from WMI in one call. On Linux, the equivalent data is scattered:

| Windows property | Linux source |
|---|---|
| `OsName`, `OsVersion` | `/etc/os-release` |
| `CsName` (hostname) | `hostnamectl` |
| `CsTotalPhysicalMemory` | `/proc/meminfo` |
| `CsNumberOfLogicalProcessors` | `/proc/cpuinfo` (count of `processor:` lines) |
| `OsUptime` | `/proc/uptime` (seconds since boot → `[TimeSpan]`) |
| `OsArchitecture` | `uname -m` |
| `TimeZone` | `timedatectl` |

The `-Property` parameter lets callers request specific properties. The implementation only reads the relevant sources for the requested properties — no need to run all sub-commands if you only want `OsName`.

One gotcha during development: `CsNumberOfLogicalProcessors` was initially implemented as `CsNumberOfProcessors` (the physical core count from `lscpu`). These are different properties on Windows too. The fix required re-reading the Windows property names carefully.

### Rename-Computer and the elevation check

`hostnamectl set-hostname` requires root. The function checks `id -u` before calling it.

**Removed in v0.4.0:** `Restart-Computer` and `Stop-Computer` were originally included because they are part of `Microsoft.PowerShell.Management`. However, they are already native cross-platform cmdlets in PowerShell 7 (`ComputerUnix.cs` in the PS source tree ships them on all platforms). Overriding them with a module implementation creates confusion — importing this module changed the behaviour of working native cmdlets. The Stage 5 cmdlet gap refresh confirmed this. See [Part 16](https://peppekerstens.github.io/the-list-was-a-year-old-linux-command-wrapping-part-16/) for the full investigation.

```powershell
if ((& id -u) -ne '0') {
    throw 'Rename-Computer requires root privileges. Run with sudo.'
}
```

This gives a clear error rather than letting `hostnamectl` fail with a confusing permission message.

### The stubs

`Resume-Service` and `Suspend-Service` exist in Windows to pause and resume services (think `SIGSTOP`/`SIGCONT`). Linux has those signals but there is no general-purpose way to implement them at the `systemctl` level — some services would handle it, others would crash. They get stubs for now. Same for `Set-Service`, `New-Service`, and `Remove-Service` — those have Linux equivalents (writing systemd unit files) but the parameter mapping is non-trivial and the use cases are uncommon enough that getting it wrong costs more than getting it right is worth.

---

## Implementation notes

- `Get-Service` uses `systemctl list-units --output=json` (running state) and `list-unit-files --output=json` (start type) joined on service name (`.service` suffix stripped). JSON parsing eliminates column-width fragility from earlier text-split approach.
- Status mapping: `active/running` → `Running`, `active/exited` → `Stopped`, `inactive/dead` → `Stopped`, `failed/failed` → `Stopped`.
- StartType mapping: `enabled` → `Automatic`, `disabled` → `Disabled`, `static` → `Manual`.
- `Get-ComputerInfo` assembles a single `PSCustomObject` from multiple `/proc` and system files; `-Property` filters which properties are populated, skipping unnecessary reads.
- `Rename-Computer` checks `id -u` for root before calling `hostnamectl`.
- All write cmdlets use `SupportsShouldProcess` — `-WhatIf` and `-Confirm` work.

---

## CI / Testing

Tested across 5 Linux distributions in containers:

| Distro | Image |
|---|---|
| Ubuntu 24.04 | `ghcr.io/peppekerstens/testinfra:ubuntu-24.04` |
| Debian 12 | `ghcr.io/peppekerstens/testinfra:debian-12` |
| Fedora 40 | `ghcr.io/peppekerstens/testinfra:fedora-40` |
| openSUSE Tumbleweed | `ghcr.io/peppekerstens/testinfra:opensuse-tumbleweed` |
| Arch Linux | `ghcr.io/peppekerstens/testinfra:arch-latest` |

Run locally with:

```powershell
# From the repo root
docker compose -f docker-compose.test.yml up --abort-on-container-exit
```

GitHub Actions runs the same matrix on every push — see `.github/workflows/pester.yml`.
---

## Version history

| Version | Notes |
|---|---|
| 0.4.0 | Removed `Restart-Computer` and `Stop-Computer` — they are already native cross-platform cmdlets in PowerShell 7 and should not be overridden. Count updated: 6 implemented, 7 stubs. |
| 0.3.0 | `Get-Service` rewritten to use `systemctl list-units/list-unit-files --output=json`. Eliminates text-split column parsing; `HashSet` replaces linear `Where-Object` for duplicate detection. |
| 0.2.0 | Linux-only guard added (throws on Windows). `Get-ComputerInfo` gains `CsNumberOfLogicalProcessors` and `OsUptime` properties; `-Property` filter fixed. Tests rewritten for Pester 5.2+: 60/60 pass on WSL2. |
| 0.1.0 | Initial release. `Get-Service`, `Start-Service`, `Stop-Service`, `Restart-Service`, `Get-ComputerInfo`, `Rename-Computer` implemented. Stubs for remaining 7. |

---

## License

GPL-3.0 — see [LICENSE](LICENSE).
