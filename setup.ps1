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
Write-HorizontalRule
Write-Output "$ICON_ROCKET  Setting up ScruthSystem$ICON_TM $ComputerName, a Windows computer"
Write-HorizontalRule

# 1Password CLI
$ok = Install-WingetPackage -CheckCmd 'op' -WingetId 'AgileBits.1Password.CLI' -PrettyName '1Password CLI'
if (-not $ok)
{
    Write-Warning "$ICON_CROSS  Please install 1Password CLI manually and re-run this script."
    exit 1
}
Ensure-SystemPathEntry -CmdBasePath "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\AgileBits.1Password.CLI_Microsoft.Winget.Source_8wekyb3d8bbwe" -CmdFile 'op.exe' -PrettyName '1Password CLI (op)'

# chezmoi installation
$ok = Install-WingetPackage -CheckCmd 'chezmoi' -WingetId 'twpayne.chezmoi' -PrettyName 'chezmoi'
if (-not $ok)
{
    Write-Warning "$ICON_CROSS  Please install chezmoi manually and re-run this script."
    exit 1
}
Ensure-SystemPathEntry -CmdBasePath "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\twpayne.chezmoi_Microsoft.Winget.Source_8wekyb3d8bbwe" -CmdFile 'chezmoi.exe' -PrettyName 'chezmoi'

###############################################################################
# Run the remainder of the script in an elevated context.
###############################################################################
Write-Output "$ICON_INFO  Initializing and applying chezmoi in an elevated context"

$url  = "https://raw.githubusercontent.com/sbfeinstein/scruth-config/refs/heads/main/setup/windows/setup_chezmoi.ps1"
$epochMs = [int64]([DateTimeOffset]::Now.ToUnixTimeMilliseconds())
$temp = "$env:TEMP\scruth-config_setup_chezmoi_$epochMs.ps1"
$log = "$env:TEMP\scruth-config_setup_chezmoi_$epochMs.log"

# Download the script from GitHub
Invoke-WebRequest -Uri $url -OutFile $temp

# Create the log as this parent process, so it can read it later.
# Wouldn't have access to a file created by the elevated command below.
New-Item -Path $log -ItemType File -Force | Out-Null
Clear-Content $log

# Execute the chezmoi setup script from an elevated process
$cmd = @"
& `"$temp`"
"@
$proc = Start-Process powershell.exe `
    -ArgumentList @(
    "-NoProfile"
    "-ExecutionPolicy Bypass"
    "-Command $cmd"
    "*>`"$log`""
) `
    -Verb RunAs `
    -PassThru `
    -WindowStyle Hidden

# Tail the log while the elevated process runs, and wait for it to end
Get-Content -Path $log -Wait
Wait-Process -Id $proc.Id

Write-Output "$ICON_CHECK  Done initializing and applying chezmoi in an elevated context"
Write-Output "$ICON_GLASSES  Finished setting up $ComputerName"
Write-HorizontalRule
Write-Output "$ICON_MAGE  Additional steps to do manually!"
Write-Output "    $UNICODE_BULLET In a non-elevated Terminal, install additional user-space applications: "
Write-Output "      winget import -i C:\Users\scott\.scruth_default_winget.json [alias Install-WinGetDefault]"
Write-HorizontalRule
