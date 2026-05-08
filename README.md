# PowerShell.Management.Linux

A PowerShell 7.x module that bridges the cmdlet gap between Windows PowerShell and Linux PowerShell for the `Microsoft.PowerShell.Management` module area.

Part of the **Linux PowerShell Cmdlet Parity** project — inspired by Evgenij Smirnov's [2025 European PowerShell Summit session](https://www.youtube.com/watch?v=RlzinWYIjBY) and the blog series at [peppekerstens.github.io](https://peppekerstens.github.io/linux-command-wrapping-part-1/).

---

## What it does

On **Linux**, it wraps native CLI tools (`systemctl`, `hostnamectl`, `shutdown`, `/proc`, `/etc/os-release`) to provide PowerShell cmdlets that match the Windows `Microsoft.PowerShell.Management` API as closely as possible.

On **Windows**, every function delegates transparently to the built-in `Microsoft.PowerShell.Management` cmdlet — no behavioral change.

---

## Cmdlet Status

| Cmdlet              | Linux Implementation        | Notes                                                    |
|---------------------|-----------------------------|----------------------------------------------------------|
| `Get-Service`       | `systemctl list-units`      | Name, DisplayName, Status, StartType                     |
| `Start-Service`     | `systemctl start`           | Pipeline, PassThru, ShouldProcess                        |
| `Stop-Service`      | `systemctl stop`            | Pipeline, PassThru, Force, ShouldProcess                 |
| `Restart-Service`   | `systemctl restart`         | Pipeline, PassThru, Force, ShouldProcess                 |
| `Get-ComputerInfo`  | `/proc`, `/etc/os-release`, `uname`, `hostnamectl` | Property filter supported       |
| `Rename-Computer`   | `hostnamectl set-hostname`  | Requires root/sudo                                       |
| `Restart-Computer`  | `shutdown -r`               | Requires root/sudo                                       |
| `Stop-Computer`     | `shutdown -h`               | Requires root/sudo                                       |
| `Resume-Service`    | Stub (warning)              | No Linux equivalent for paused services                  |
| `Suspend-Service`   | Stub (warning)              | No Linux equivalent                                      |
| `Set-Service`       | Stub (warning)              | Future: systemctl enable/disable                         |
| `New-Service`       | Stub (warning)              | Future: systemd unit file creation                       |
| `Remove-Service`    | Stub (warning)              | Future: systemd unit file removal                        |
| `Get-HotFix`        | Stub (warning)              | N/A on Linux                                             |
| `Clear-RecycleBin`  | Stub (warning)              | N/A on Linux                                             |

### Not included (already work natively in PS7 on Linux)
`Get-Process`, `Stop-Process`, `Start-Process`, `Wait-Process`, `Get-ChildItem`, `Get-Item`, `Set-Item`, `Get-Content`, `Set-Content`, `Get-Location`, `Set-Location`, `Test-Path`, `Test-Connection`, `Get-TimeZone`, `Set-TimeZone`, and all filesystem/path cmdlets.

---

## Requirements

- PowerShell 7.2+
- Linux with systemd (Ubuntu 20.04+, Debian 11+, etc.)
- `systemctl` for service management
- `hostnamectl` for computer rename
- Root / sudo for `Rename-Computer`, `Restart-Computer`, `Stop-Computer`

---

## Installation

```powershell
# Clone or copy module to a PSModulePath location, then:
Import-Module PowerShell.Management.Linux
```

---

## Usage

```powershell
# List all running services
Get-Service | Where-Object Status -eq Running

# Filter by name (wildcard)
Get-Service -Name 'ssh*'

# Restart a service
Restart-Service -Name 'ssh' -PassThru

# Get system info
Get-ComputerInfo

# Rename the host (requires root)
Rename-Computer -NewName 'myserver' -Force
```

---

## License

GPL-3.0 — see [LICENSE](LICENSE).
