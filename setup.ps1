# Set console to UTF8 to ensure emojis render correctly in the terminal
$OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

###############################################################################
# Helpers and initialization
###############################################################################

function Add-SystemPathEntry {
    param(
        [string]$CmdBasePath,
        [string]$CmdFile,
        [string]$PrettyName
    )
    if (-not $CmdBasePath) {
        Write-Host "WARN: $PrettyName is not managed by WinGet so can't enforce it being in the System Path"
        return
    }

    $binFolder = (Get-ChildItem -Path $CmdBasePath -Filter $CmdFile -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).DirectoryName
    if (-not $binFolder) {
        Write-Host "WARN: Could not locate $CmdFile from $CmdBasePath to add to PATH with $binFolder. Please check the installation."
        return
    }

    $oldPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")

    if ($oldPath -like "*$binFolder*") {
        Write-Host "Path for $PrettyName is already in System PATH."
        $env:Path = Get-CurrentPathEnv
        return
    }

    # Write old path to a file for safety's sake
    $systemPathHistoryFile = "$HOME\.scruth-config\system_path_history.log"
    New-Item -Path "$HOME\.scruth-config" -ItemType Directory -Force | Out-Null
    Add-Content -Path $systemPathHistoryFile -Value "$( Get-Date )`n$oldPath`n`n"

    # Need an elevated process to update the system path
    $newPathValue = "$oldPath;$binFolder"
    $sb = [ScriptBlock]::Create("
        [Environment]::SetEnvironmentVariable('PATH', '$newPathValue', 'Machine')
    ")
    $params = @{
        DisplayLabel = "ensuring system path element for $PrettyName"
        ScriptBlock = $sb
    }
    Invoke-ElevatedCommand @params

    # Update system path in this process
    $env:Path = Get-CurrentPathEnv
    return
}

function Find-InstallLocation {
    param(
        [string]$Pkg
    )
    return winget list --details -e $Pkg |
            Select-String 'Installed Location:' |
            ForEach-Object { $_.ToString().Split(':', 2)[1].Trim() }
}

function Get-CurrentPathEnv {
    return [System.Environment]::ExpandEnvironmentVariables(([System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")))
}

function Initialize-1Password {
    # This setup script does not install the 1password desktop app or Chrome extension.
    # Manually installing the desktop app integration may make it easier to sign-in via the op CLI
    # See https://developer.1password.com/docs/cli/get-started#step-2-turn-on-the-1password-desktop-app-integration

    # May need to remove a session file created from an elevated context manually
    # either op signout
    # or Remove-Item -Recurse -Force "$env:LOCALAPPDATA\Temp\com.agilebits.op*"
    # from an elevated context

    while ($true) {
        & op whoami *>$null
        if ($LASTEXITCODE -eq 0) { break }

        Write-Host "Please login to 1Password in order to continue"
        op signin | Invoke-Expression
        if ($LASTEXITCODE -eq 0) { break }
    }
}

function Install-WingetPackage {
    param(
        [string]$CheckCmd,
        [string]$WingetId,
        [string]$PrettyName,
        [string]$OtherParameters = ""
    )

    if (Test-CommandExists $CheckCmd) {
        Write-Host "$PrettyName already installed"
        return
    }

    # Check winget
    if (-not (Test-CommandExists 'winget')) {
        Write-Host "WARN: winget not found. Please install winget or install $PrettyName manually."
        exit 1
    }

    Write-Host "Installing $PrettyName via winget (id: $WingetId) ..."
    $fullCommand = "winget install --accept-package-agreements --accept-source-agreements --id $WingetId $OtherParameters"
    Invoke-Expression "$fullCommand 2>&1" | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARN: winget failed to install $PrettyName (exit code $LASTEXITCODE)"
        exit 1
    }
    Write-Host "$PrettyName installed"
}

function Invoke-ElevatedCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DisplayLabel,

        [Parameter(Mandatory)]
        [ScriptBlock]$ScriptBlock,

        [switch]$Quiet,
        [switch]$NoExecutionPolicy
    )

    #
    # Create a unique temporary log file that the *non‑elevated* caller can read.
    #
    $epoch = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
    $logPath = Join-Path $env:TEMP "InvokeElevated_$epoch.log"
    New-Item -Path $logPath -ItemType File -Force | Out-Null
    Clear-Content -Path $logPath

    if (-not $Quiet) {
        Write-Host "Executing elevated script for $DisplayLabel, logging to $logPath"
    }

    #
    # Wrap the command so its output (including errors) is both displayed in the new window and logged
    #
    $commandText = "& { " + $ScriptBlock.ToString().Replace('"', '\"') + " } 2>&1 | Tee-Object -FilePath `"$logPath`""

    # Run elevated and wait to finish
    $argList = @(
        "-NoProfile"
    )
    if (-not $NoExecutionPolicy) {
        $argList += "-ExecutionPolicy", "Bypass"
    }
    $argList += "-Command", $commandText

    $proc = Start-Process -FilePath "powershell.exe" `
        -ArgumentList $argList `
        -Verb  RunAs `
        -PassThru `
        -Wait

    # Display the logged output in the current process
    Get-Content -Path $logPath
    $exit = $proc.ExitCode

    if (-not $Quiet) {
        Write-Host "Done $DisplayLabel (exit $exit)."
    }

}

function Test-CommandExists {
    param([string]$CmdName)
    $c = Get-Command $CmdName -ErrorAction SilentlyContinue
    if ($null -ne $c) {
        return $true
    }
    return $false
}

function Test-IsAdmin {
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    return $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Require running from a regular, not elevated, terminal so that user-specific
# installs, etc, happen correctly
if (Test-IsAdmin) {
    Write-Host "WARN: Please run this script from an unelevated Powershell (5.1+) Terminal."
    exit 1
}

# Change execution Policy to RemoteSigned so that scripts such as this script spawns are allowed to run
# See https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_execution_policies?view=powershell-5.1
$executionPolicy = Get-ExecutionPolicy
if ($executionPolicy -ne 'RemoteSigned') {
    Write-Host "Updating execution policy from '$executionPolicy' to 'RemoteSigned'."
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
# Bootstrap
###############################################################################

Write-Host "Bootstrapping scruth-config..."

# 1Password CLI
$1pwdPackage = 'AgileBits.1Password.CLI'
Install-WingetPackage -CheckCmd 'op' -WingetId $1pwdPackage -PrettyName '1Password CLI'
$1pwdPath = Find-InstallLocation $1pwdPackage
Add-SystemPathEntry -CmdBasePath $1pwdPath -CmdFile 'op.exe' -PrettyName '1Password CLI (op)'
Initialize-1Password

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
    Write-Host "Chezmoi already initialized, updating from repo..."

    & chezmoi update --apply=false

    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARN: chezmoi update returned exit code $LASTEXITCODE"
        exit 1
    }

    Write-Host "Finished updating Chezmoi from repo"
} else {
    Write-Host "Initializing Chezmoi..."
    & chezmoi init $RepoToInit --branch $RepoBranch
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARN: chezmoi init failed (exit code $LASTEXITCODE)"
        exit 1
    }
    & chezmoi init # HACK to avoid "your config needs to be regenerated" message, likely due to changing sourceDir
    if ($LASTEXITCODE -ne 0) {
        Write-Host "WARN: chezmoi 2nd init failed (exit code $LASTEXITCODE)"
        exit 1
    }
    Write-Host "Finished Initializing Chezmoi"
}

Write-Host "Finished bootstrapping scruth-config"
Write-Host "Applying Chezmoi"
& chezmoi apply
