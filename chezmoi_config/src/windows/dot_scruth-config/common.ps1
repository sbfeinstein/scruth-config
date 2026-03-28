###############################################################################
# scruth-config common.ps1
# Helpful constants and functions that are used for scruth-config's setup
# and other scripts.
# May also be useful as general PowerShell profile additions.  Can include
# in PowerShell profile files (including automatic management via scruth-confg)
# by sourcing.
###############################################################################

###############################################################################
# Emoji constants (PowerShell 5.1+ compatible)
#
# https://www.w3schools.com/charsets/ref_emoji.asp
#
# You can get the write hex code to use for a given single-character symbol via:
# "0x{0:X4}" -f [int][char]'•' # outputs 0x2022
# "0x{0:X4}" -f [int][char]'•' # outputs 0x2022
###############################################################################

$ICON_INFO     = [char]::ConvertFromUtf32(0x2139) + [char]::ConvertFromUtf32(0xFE0F)
$ICON_CROSS    = [char]::ConvertFromUtf32(0x274C)
$ICON_CHECK    = [char]::ConvertFromUtf32(0x2705)
$ICON_MAGE     = [char]::ConvertFromUtf32(0x1F9D9)
$ICON_ROCKET   = [char]::ConvertFromUtf32(0x1F680)
$ICON_GLASSES  = [char]::ConvertFromUtf32(0x1F60E)
$ICON_TM       = [char]::ConvertFromUtf32(0x2122)
$ICON_WRENCH   = [char]::ConvertFromUtf32(0x1F527)
$ICON_WARNING  = [char]::ConvertFromUtf32(0x26A0) + [char]::ConvertFromUtf32(0xFE0F)

$UNICODE_BULLET = [char]::ConvertFromUtf32(0x2022)
$UNICODE_EMDASH = [char]::ConvertFromUtf32(0x2014)

###############################################################################
# Helpful functions
###############################################################################

function Add-SystemPathEntry {
    param(
        [string]$CmdBasePath,
        [string]$CmdFile,
        [string]$PrettyName
    )
    if (-not $CmdBasePath) {
        Write-Warning "$ICON_CROSS  $PrettyName is not managed by WinGet so can't enforce it being in the System Path"
        return
    }

    $binFolder = (Get-ChildItem -Path $CmdBasePath -Filter $CmdFile -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1).DirectoryName
    if (-not $binFolder) {
        Write-Warning "$ICON_CROSS  Could not locate $CmdFile from $CmdBasePath to add to PATH with $binFolder. Please check the installation."
        return
    }

    $oldPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")

    if ($oldPath -like "*$binFolder*") {
        Write-Host "$ICON_INFO  Path for $PrettyName is already in System PATH."
        $env:Path = Get-CurrentPathEnv
        return
    }

    # Write old path to a file for safety's sake
    $systemPathHistoryFile = "$HOME\.scruth-config\system_path_history.log"
    New-Item -Path "$HOME\.scruth-config" -ItemType Directory -Force | Out-Null
    Add-Content -Path $systemPathHistoryFile -Value "$(Get-Date)`n$oldPath`n`n"

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
    return [System.Environment]::ExpandEnvironmentVariables(([System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")))
}

function Install-WinGetDefault {
    & winget import -i "$HOME\.scruth-config\.scruth_default_winget.json" @args
}

function Install-WingetPackage {
    param(
        [string]$CheckCmd,
        [string]$WingetId,
        [string]$PrettyName,
        [string]$OtherParameters = ""
    )

    if (Test-CommandExists $CheckCmd) {
        Write-Host "$ICON_INFO  $PrettyName already installed"
        return
    }

    # Check winget
    if (-not (Test-CommandExists 'winget')) {
        Write-Warning "$ICON_CROSS  winget not found. Please install winget or install $PrettyName manually."
        exit 1
    }

    Write-Host "$ICON_WRENCH  Installing $PrettyName via winget (id: $WingetId) ..."
    $fullCommand = "winget install --accept-package-agreements --accept-source-agreements --id $WingetId $OtherParameters"
    Invoke-Expression "$fullCommand 2>&1" | Out-Host
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "$ICON_CROSS  winget failed to install $PrettyName (exit code $LASTEXITCODE)"
        exit 1
    }
    Write-Host "$ICON_CHECK  $PrettyName installed"
}

function Invoke-ElevatedCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$DisplayLabel,

        [Parameter(Mandatory)]
        [ScriptBlock]$ScriptBlock,

        [switch]$Quiet
    )

    #
    # Create a unique temporary log file that the *non‑elevated* caller can read.
    #
    $epoch = [DateTimeOffset]::Now.ToUnixTimeMilliseconds()
    $logPath = Join-Path $env:TEMP "InvokeElevated_$epoch.log"
    New-Item -Path $logPath -ItemType File -Force | Out-Null
    Clear-Content -Path $logPath

    if (-not $Quiet) {
        Write-Output "$ICON_INFO  Executing elevated script for $DisplayLabel, logging to $logPath"
    }

    #
    # Wrap the command so its output (including errors) is both displayed in the new window and logged
    #
    $commandText = "& { " + $ScriptBlock.ToString().Replace('"', '\"') + " } 2>&1 | Tee-Object -FilePath `"$logPath`""

    # Run elevated and wait to finish
    $proc = Start-Process -FilePath "powershell.exe" `
        -ArgumentList @(
            "-NoProfile"
            "-ExecutionPolicy", "Bypass"
            "-Command", $commandText
        ) `
        -Verb RunAs `
        -PassThru `
        -Wait

    # Display the logged output in the current process
    Get-Content -Path $logPath
    $exit = $proc.ExitCode

    if (-not $Quiet) {
        Write-Output "$ICON_CHECK  Done $DisplayLabel (exit $exit)."
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

function Write-HostHorizontalRule {
    Write-Host ($UNICODE_EMDASH * $Host.UI.RawUI.WindowSize.Width) -ForegroundColor DarkCyan
}

function Write-HostInfo {
    param([string]$str)
    Write-Host "$ICON_INFO  $str"
}

function Write-HostCaution {
    param([string]$str)
    Write-Host "$ICON_INFO  $str" -ForegroundColor Yellow
}

function Write-WarningCaution {
    param([string]$str)
    Write-Warning "$ICON_CROSS  $str"
}

function Write-HostSuccess {
    param([string]$str)
    Write-Host "$ICON_CHECK  $str" -ForegroundColor Green
}
