function Rename-Computer {
    <#
    .Synopsis
        Renames the local computer.
    .Description
        Cross-platform implementation of Rename-Computer.
        On Windows, delegates to the built-in Microsoft.PowerShell.Management\Rename-Computer.
        On Linux, wraps 'hostnamectl set-hostname' (requires sudo/root or appropriate privilege).
    .Parameter NewName
        The new hostname for the computer.
    .Parameter Force
        Suppress confirmation prompts.
    .Parameter PassThru
        Return a boolean indicating success.
    .Notes
        Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
        Author: Peppe Kerstens (NLD)
        Version: 1.0.0
        Date: 2026-05-08
    .Link
        https://learn.microsoft.com/powershell/module/microsoft.powershell.management/rename-computer
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$NewName,

        [Parameter()]
        [switch]$Force,

        [Parameter()]
        [switch]$PassThru
    )

    if (-not $IsLinux) {
        Microsoft.PowerShell.Management\Rename-Computer @PSBoundParameters
        return
    }

    if (-not (Get-Command hostnamectl -ErrorAction SilentlyContinue)) {
        throw "Rename-Computer: 'hostnamectl' not found. This cmdlet requires systemd."
    }

    if ($Force -or $PSCmdlet.ShouldProcess($env:COMPUTERNAME, "Rename to '$NewName'")) {
        $output = hostnamectl set-hostname "$NewName" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Rename-Computer: Failed to rename computer. $output"
            if ($PassThru) { return $false }
        } else {
            Write-Verbose "Rename-Computer: Hostname set to '$NewName'. A reboot may be required for full effect."
            if ($PassThru) { return $true }
        }
    }
}
