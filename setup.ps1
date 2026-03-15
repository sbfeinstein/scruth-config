# Set console to UTF8 to ensure emojis render correctly in the terminal
$OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

# Imports
. ".\chezmoi_config\src\windows\.chezmoitemplates\common.ps1"
. ".\chezmoi_config\src\windows\.chezmoitemplates\emoji_constants.ps1"

$ApprovedComputerNames = @('FAMILYFUN', 'RARSTEENS')
$RepoToInit = 'sbfeinstein/scruth-config'
$RepoBranch = 'main'

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

# chezmoi init or update
$sourcePath = $null
try
{
    $raw = & chezmoi source-path 2>&1
    if ($LASTEXITCODE -eq 0)
    {
        $sourcePath = $raw.Trim()
    }
}
catch
{
    $sourcePath = $null
}

if ($sourcePath -and (Test-Path $sourcePath))
{
    Write-Host "$ICON_INFO  Chezmoi already initialized, pulling latest changes..."
    & chezmoi update
    if ($LASTEXITCODE -eq 0)
    {
        Write-Host "$ICON_CHECK  chezmoi updated"
    }
    else
    {
        Write-Warning "$ICON_CROSS  chezmoi update returned exit code $LASTEXITCODE"
        exit 1
    }
}
else
{
    Write-Host "$ICON_INFO  Chezmoi not already initialized, initializing and applying"
    & chezmoi init $RepoToInit --branch $RepoBranch
    if ($LASTEXITCODE -ne 0)
    {
        Write-Warning "$ICON_CROSS  chezmoi init failed (exit code $LASTEXITCODE)"
        exit 1
    }

    & chezmoi apply
    if ($LASTEXITCODE -ne 0)
    {
        Write-Warning "$ICON_CROSS  chezmoi apply failed (exit code $LASTEXITCODE)"
        exit 1
    }
    Write-Host "$ICON_CHECK  Chezmoi initialized"

    # Switch git to SSH since chezmoi init uses HTTPS
    git -C "$HOME/.local/share/chezmoi" remote set-url origin git@github.com:sbfeinstein/scruth-config.git
}

Write-Host "$ICON_GLASSES  Finished setting up $ComputerName"
Write-Horizontal-Rule
Write-Host "$ICON_MAGE  Additional steps to do manually!"
Write-Host "    $UNICODE_BULLET In a non-elevated Terminal, install user-space applications via either: "
Write-Host "      $UNICODE_BULLET winget import -i C:\Users\scott\.scruth_default_winget.json"
Write-Host "      $UNICODE_BULLET winget import -i C:\Users\scott\.scruth_minimal_winget.json"
Write-Horizontal-Rule