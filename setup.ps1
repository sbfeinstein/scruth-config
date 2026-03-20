# Set console to UTF8 to ensure emojis render correctly in the terminal
$OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

# Load common.ps1
$common = Invoke-RestMethod "https://raw.githubusercontent.com/sbfeinstein/scruth-config/main/chezmoi_config/src/windows/.chezmoitemplates/common.ps1"
. ([ScriptBlock]::Create($common))

# Load emoji_constants.ps1
$emoji = Invoke-RestMethod "https://raw.githubusercontent.com/sbfeinstein/scruth-config/main/chezmoi_config/src/windows/.chezmoitemplates/emoji_constants.ps1"
. ([ScriptBlock]::Create($emoji))

$ApprovedComputerNames = @('CRAFTINGISSEXY', 'FAMILYFUN', 'RARSTEENS')

# Hostname check
$ComputerName = $env:COMPUTERNAME
if (-not ($ApprovedComputerNames -contains $ComputerName))
{
    Write-Warning "$ICON_CROSS  This system ($ComputerName) is not an allowed ScruthSystem$ICON_TM, aborting setup"
    exit 1
}
Write-Horizontal-Rule
Write-Output "$ICON_ROCKET  Setting up ScruthSystem$ICON_TM $ComputerName, a Windows computer"
Write-Horizontal-Rule

# 1Password CLI
$ok = Install-Package-With-Winget -CheckCmd 'op' -WingetId 'AgileBits.1Password.CLI' -PrettyName '1Password CLI'
if (-not $ok)
{
    Write-Warning "$ICON_CROSS  Please install 1Password CLI manually and re-run this script."
    exit 1
}
Update-System-Path -CmdBasePath "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\AgileBits.1Password.CLI_Microsoft.Winget.Source_8wekyb3d8bbwe" -CmdFile 'op.exe' -PrettyName '1Password CLI (op)'

# chezmoi installation
$ok = Install-Package-With-Winget -CheckCmd 'chezmoi' -WingetId 'twpayne.chezmoi' -PrettyName 'chezmoi'
if (-not $ok)
{
    Write-Warning "$ICON_CROSS  Please install chezmoi manually and re-run this script."
    exit 1
}
Update-System-Path -CmdBasePath "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\twpayne.chezmoi_Microsoft.Winget.Source_8wekyb3d8bbwe" -CmdFile 'chezmoi.exe' -PrettyName 'chezmoi'

# Run the remainder of the script in an elevated context.
$child = Join-Path $PSScriptRoot 'setup\setup_chezmoi.ps1'

# Launch elevated and wait
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = 'powershell.exe'
$psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$child`""
$psi.Verb = 'runas'   # <-- triggers elevation
$psi.UseShellExecute = $true

Write-Host "$ICON_INFO  Initializing and applying chezmoi in an elevated context"
$proc = [System.Diagnostics.Process]::Start($psi)
$proc.WaitForExit()
Write-Host "$ICON_CHECK  Done initializing and applying chezmoi in an elevated context"

Write-Host "$ICON_GLASSES  Finished setting up $ComputerName"
Write-Horizontal-Rule
Write-Host "$ICON_MAGE  Additional steps to do manually!"
Write-Host "    $UNICODE_BULLET In a non-elevated Terminal, install user-space applications via either: "
Write-Host "      $UNICODE_BULLET winget import -i C:\Users\scott\.scruth_default_winget.json [alias Install-WinGetDefault]"
Write-Host "      $UNICODE_BULLET winget import -i C:\Users\scott\.scruth_minimal_winget.json [alias Install-WinGetMinimal]"
Write-Horizontal-Rule