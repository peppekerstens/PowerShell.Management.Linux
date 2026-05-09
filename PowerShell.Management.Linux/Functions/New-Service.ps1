function New-Service {
    <#
    .SYNOPSIS
        Creates a new systemd service unit. On Linux, writes a unit file to /etc/systemd/system/ and enables it.
    .DESCRIPTION
        Creates a simple systemd service unit file from the provided parameters,
        then runs 'systemctl daemon-reload' and optionally 'systemctl enable'.
        Requires sudo privileges on Linux.

        Unsupported Windows parameters: -DependsOn, -DisplayName (ignored),
        -SecurityDescriptorSddl, -Credential.
    .PARAMETER Name
        The service (unit) name. The '.service' suffix is added automatically.
    .PARAMETER BinaryPathName
        The command to run as the service ExecStart.
    .PARAMETER Description
        A description for the service. Becomes the systemd Description field.
    .PARAMETER DisplayName
        Ignored on Linux (no equivalent in systemd). Emits a warning.
    .PARAMETER StartupType
        Maps to systemd WantedBy: Automatic => multi-user.target enable; Manual or Disabled => no enable.
    .LINK
        https://learn.microsoft.com/powershell/module/microsoft.powershell.management/new-service
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$BinaryPathName,

        [Parameter()]
        [string]$Description = '',

        [Parameter()]
        [string]$DisplayName,

        [Parameter()]
        [ValidateSet('Automatic', 'Manual', 'Disabled')]
        [string]$StartupType = 'Manual',

        [Parameter()]
        [string]$DependsOn
    )
    process {
        if ($IsLinux) {
            if ($DisplayName) {
                Write-Warning 'New-Service: -DisplayName is not supported on Linux (no systemd equivalent).'
            }
            if ($DependsOn) {
                Write-Warning 'New-Service: -DependsOn is not supported on Linux. Use After= in the unit file directly.'
            }

            $unitName = "$Name.service"
            $unitPath = "/etc/systemd/system/$unitName"

            if ($PSCmdlet.ShouldProcess($unitPath, 'Create systemd service unit')) {
                $unitLines = @(
                    '[Unit]',
                    "Description=$Description",
                    '',
                    '[Service]',
                    "ExecStart=$BinaryPathName",
                    'Restart=no',
                    '',
                    '[Install]',
                    'WantedBy=multi-user.target'
                )
                $tmpFile = [System.IO.Path]::GetTempFileName()
                try {
                    [System.IO.File]::WriteAllLines($tmpFile, $unitLines)
                    & sudo cp $tmpFile $unitPath
                    if ($LASTEXITCODE -ne 0) {
                        Write-Error "Failed to write unit file $unitPath"
                        return
                    }
                } finally {
                    Remove-Item $tmpFile -Force -ErrorAction SilentlyContinue
                }
                & sudo systemctl daemon-reload
                if ($StartupType -eq 'Automatic') {
                    & sudo systemctl enable $unitName 2>&1 | Out-Null
                }
                [PSCustomObject]@{
                    Name           = $Name
                    DisplayName    = $Name
                    Status         = 'Stopped'
                    StartType      = $StartupType
                    BinaryPathName = $BinaryPathName
                }
            }
        } else {
            Microsoft.PowerShell.Management\New-Service @PSBoundParameters
        }
    }
}
