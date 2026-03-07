# Set console to UTF8 to ensure emojis render correctly in the terminal
$OutputEncoding = [Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

# Define Emoji Constants using Hex codes (PS 5.1 compatible)
$ICON_INFO    = [char]::ConvertFromUtf32(0x2139) + [char]::ConvertFromUtf32(0xFE0F) # ℹ️
$ICON_CROSS   = [char]::ConvertFromUtf32(0x274C) # ❌
$ICON_CHECK   = [char]::ConvertFromUtf32(0x2705) # ✅
$ICON_ROCKET  = [char]::ConvertFromUtf32(0x1F680) # 🚀
$ICON_GLASSES = [char]::ConvertFromUtf32(0x1F60E) # 😎

$ApprovedComputerNames = @('FAMILYFUN', 'RARSTEENS')
$RepoToInit = 'sbfeinstein/scruth-config'
$RepoBranch = 'sfeinstein_windows_support'

# Helper to check for a command
function Find-Command-Exists
{
    param([string]$CmdName)
    $c = Get-Command $CmdName -ErrorAction SilentlyContinue
    if ($null -ne $c)
    {
        return $true
    }
    return $false
}

# Helper to install a package via winget
function Install-Package-With-Winget
{
    param(
        [string]$CheckCmd,
        [string]$WingetId,
        [string]$PrettyName
    )

    if (Find-Command-Exists $CheckCmd)
    {
        Write-Host "$ICON_INFO  $PrettyName already installed"
        return $true
    }

    # Check winget
    if (-not (Find-Command-Exists 'winget'))
    {
        Write-Warning "$ICON_CROSS  winget not found. Please install winget or install $PrettyName manually."
        return $false
    }

    Write-Host "🔧  Installing $PrettyName via winget (id: $WingetId) ..."
    & winget install --accept-package-agreements --accept-source-agreements --id $WingetId
    if ($LASTEXITCODE -eq 0)
    {
        Write-Host "$ICON_CHECK  $PrettyName installed"
        return $true
    }
    else
    {
        Write-Warning "$ICON_CROSS  winget failed to install $PrettyName (exit code $LASTEXITCODE)"
        return $false
    }
}

# Helper to update the system path
function Update-System-Path
{
    param(
        [string]$CmdBasePath,
        [string]$CmdFile,
        [string]$PrettyName
    )

    $binFolder = (Get-ChildItem -Path $CmdBasePath -Filter $CmdFile -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).DirectoryName

    if ($binFolder)
    {
        # 3. Add to System PATH
        $oldPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($oldPath -notlike "*$binFolder*")
        {
            [Environment]::SetEnvironmentVariable("PATH", "$oldPath;$binFolder", "Machine")
            Write-Host "$ICON_CHECK  Added $binFolder to System PATH."
        }
        else
        {
            Write-Host "$ICON_INFO  Path for $PrettyName is already in System PATH."
        }
    }
    else
    {
        Write-Warning "$ICON_CROSS  Could not locate $CmdFile from $CmdBasePath to add to PATH with $binFolder. Please check the installation."
        exit 1
    }
}

# Hostname check
$ComputerName = $env:COMPUTERNAME
if (-not ($ApprovedComputerNames -contains $ComputerName))
{
    Write-Warning "$ICON_CROSS  This system ($ComputerName) is not an allowed ScruthSystem™️ , aborting setup"
    exit 1
}
Write-Output "$ICON_ROCKET  Setting up ScruthSystem™️  $ComputerName"

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
}

Write-Host "$ICON_GLASSES  Finished setting up $ComputerName"
Write-Host "$ICON_INFO  Set upstream to SSH rather than HTTPS via:"
Write-Host "    chezmoi cd"
Write-Host "    git remote set-url origin git@github.com:sbfeinstein/scruth-config.git"
