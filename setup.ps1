# Set console to UTF8 to ensure emojis render correctly in the terminal
$OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

###############################################################################
# Source remote constants and helpers, abort if we're in an elevated context
###############################################################################
$common = Invoke-RestMethod "https://raw.githubusercontent.com/sbfeinstein/scruth-config/main/chezmoi_config/src/windows/dot_scruth-config/common.ps1"
. ([ScriptBlock]::Create($common))

if (Test-IsAdmin) {
    Write-Warning "$ICON_CROSS  Please run this script from an unelevated Powershell (5.1+) Terminal."
    exit 1
}

###############################################################################
# Execution Policy to RemoteSigned
# See https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1
###############################################################################

$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -ne 'RemoteSigned') {
    Write-HostCaution "Updating execution policy from '$executionPolicy' to 'RemoteSigned'."
    $sb = [ScriptBlock]::Create(@"
    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
"@)
    $params = @{
        DisplayLabel = 'updating execution policy to RemoteSigned'
        ScriptBlock = $sb
        NoExecutionPolicy = $true
    }
    Invoke-ElevatedCommand @params
}

###############################################################################
# Install chezmoi and dependencies
###############################################################################
Write-HostHorizontalRule
Write-Host "$ICON_ROCKET  Bootstrapping scruth-config, the ScruthSystem$ICON_TM manager extraordinaire!"
Write-HostInfo "You may need to manually configure OneDrive to *not* sync Documents and other folders"
Write-HostHorizontalRule

# 1Password CLI
$1pwdPackage = 'AgileBits.1Password.CLI'
Install-WingetPackage -CheckCmd 'op' -WingetId $1pwdPackage -PrettyName '1Password CLI'
$1pwdPath = Find-InstallLocation $1pwdPackage
Add-SystemPathEntry -CmdBasePath $1pwdPath -CmdFile 'op.exe' -PrettyName '1Password CLI (op)'

# chezmoi installation
$chezmoiPackage = 'twpayne.chezmoi'
Install-WingetPackage -CheckCmd 'chezmoi' -WingetId $chezmoiPackage -PrettyName 'chezmoi'
$chezmoiPath = Find-InstallLocation $chezmoiPackage
Add-SystemPathEntry -CmdBasePath $chezmoiPath -CmdFile 'chezmoi.exe' -PrettyName 'chezmoi'

###############################################################################
# Init and apply chezmoi
###############################################################################

$RepoToInit = 'sbfeinstein/scruth-config'
$RepoBranch = 'main'

# chezmoi init or update
$sourcePath = $null
try {
    $rawSourcePath = & chezmoi source-path 2>&1
    if ($LASTEXITCODE -eq 0) {
        $sourcePath = $rawSourcePath.Trim()
    }
}
catch {
    $sourcePath = $null
}

if ($sourcePath -and (Test-Path $sourcePath)) {
    Write-Output "$ICON_INFO  Chezmoi already initialized, pulling latest changes..."

    & chezmoi update

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "$ICON_CROSS  chezmoi update returned exit code $LASTEXITCODE"
        exit 1
    }

    Write-Output "$ICON_CHECK  chezmoi updated and applied"
    return
}

Write-Output "$ICON_INFO  Initializing and applying chezmoi..."

& chezmoi init $RepoToInit --branch $RepoBranch
if ($LASTEXITCODE -ne 0) {
    Write-Warning "$ICON_CROSS  chezmoi init failed (exit code $LASTEXITCODE)"
    exit 1
}
& chezmoi init # HACK to avoid "your config needs to be regenerated" message, likely due to changing sourceDir

& chezmoi apply
if ($LASTEXITCODE -ne 0) {
    Write-Warning "$ICON_CROSS  chezmoi apply failed (exit code $LASTEXITCODE)"
    exit 1
}
