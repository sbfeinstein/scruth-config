# Set console to UTF8 to ensure emojis render correctly in the terminal
$OutputEncoding = [Console]::OutputEncoding = New-Object System.Text.UTF8Encoding($false)

# Load emoji_constants.ps1
$emoji = Invoke-RestMethod "https://raw.githubusercontent.com/sbfeinstein/scruth-config/main/chezmoi_config/src/windows/.chezmoitemplates/emoji_constants.ps1"
. ([ScriptBlock]::Create($emoji))

$RepoToInit = 'sbfeinstein/scruth-config'
$RepoBranch = 'main'

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

    # Additional init perhaps due to a chezmoi bug?
    # It otherwise, on chezmoi apply, outputs a warning that init needs to be re-run because
    # the config is out of sync.
    & chezmoi init

    Write-Host "$ICON_CHECK  Chezmoi initialized"

    # Switch git to SSH since chezmoi init uses HTTPS
    git -C "$HOME/.local/share/chezmoi" remote set-url origin git@github.com:sbfeinstein/scruth-config.git
    Write-Host "$ICON_CHECK  Forced git to SSH for ~/.local/share/chezmoi"
}
