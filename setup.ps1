# Set console to UTF8 to ensure emojis render correctly in the terminal
$OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

###############################################################################
# Source remote constants and helpers, abort if we're in an elevated context
###############################################################################
$common = Invoke-RestMethod "https://raw.githubusercontent.com/sbfeinstein/scruth-config/main/chezmoi_config/src/windows/dot_scruth-config/common.ps1"
. ([ScriptBlock]::Create($common))

if (Test-IsAdmin)
{
    Write-Warning "$ICON_CROSS  Please run this script from an unelevated Powershell (5.1+) Terminal."
    exit 1
}

###############################################################################
# Bootstrapping chezmoi and dependencies
###############################################################################
Write-HorizontalRule
Write-Output "$ICON_ROCKET  Bootstrapping scruth-config, the ScruthSystem$ICON_TM manager extraordinaire!"
Write-HorizontalRule

# 1Password CLI
$1pwdPackage = 'AgileBits.1Password.CLI'
$ok = Install-WingetPackage -CheckCmd 'op' -WingetId $1pwdPackage -PrettyName '1Password CLI'
if (-not $ok)
{
    Write-Warning "$ICON_CROSS  Please install 1Password CLI manually and re-run this script."
    exit 1
}
$1pwdPath = Find-InstallLocation $1pwdPackage
Ensure-SystemPathEntry -CmdBasePath $1pwdPath -CmdFile 'op.exe' -PrettyName '1Password CLI (op)'

# chezmoi installation
$chezmoiPackage = 'twpayne.chezmoi'
$ok = Install-WingetPackage -CheckCmd 'chezmoi' -WingetId $chezmoiPackage -PrettyName 'chezmoi'
if (-not $ok)
{
    Write-Warning "$ICON_CROSS  Please install chezmoi manually and re-run this script."
    exit 1
}
$chezmoiPath = Find-InstallLocation $chezmoiPackage
Ensure-SystemPathEntry -CmdBasePath $chezmoiPath -CmdFile 'chezmoi.exe' -PrettyName 'chezmoi'
