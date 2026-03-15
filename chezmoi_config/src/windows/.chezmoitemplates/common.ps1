# Imports
@'
{{ template "emoji_constants.ps1" . }}
'@ | Out-Null

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

function Install-Package-With-Winget
{
    param(
        [string]$CheckCmd,
        [string]$WingetId,
        [string]$PrettyName,
        [string]$OtherParameters = ""
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

    Write-Host "$ICON_WRENCH  Installing $PrettyName via winget (id: $WingetId) ..."
    & winget install --accept-package-agreements --accept-source-agreements --id $WingetId $OtherParameters
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

function Write-Horizontal-Rule
{
    Write-Host ($UNICODE_EMDASH * $Host.UI.RawUI.WindowSize.Width) -ForegroundColor DarkCyan
}
