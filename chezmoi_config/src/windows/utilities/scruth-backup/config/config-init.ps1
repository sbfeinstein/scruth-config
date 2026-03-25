. $PWD\utils\log-utils.ps1

function Initialize-Config {

    param (
        [Parameter(Mandatory)]
        [string]$SourceComputer
    )

    # Load the default settings
    $defaultSettings = Import-PowerShellDataFile -LiteralPath "$PSScriptRoot\default.psd1"

    # Load the default dynamic settings
    $defaultSettings['rclone_exec_path'] = (Get-Command rclone).Path

    # Load the source-specific settings
    $specificSettings = Import-PowerShellDataFile -LiteralPath "$PSScriptRoot\$SourceComputer.psd1"

    # Merge settings, preferring specific settings
    $mergedSettings = @{}
    $mergedSettings = $defaultSettings.Clone()
    foreach ($key in $specificSettings.Keys) {
        $mergedSettings[$key] = $specificSettings[$key]
    }

    # Load the destination settings
    $destinationComputer = $mergedSettings['destination_computer']
    $destinationSettings = Import-PowerShellDataFile -LiteralPath "$PSScriptRoot\$destinationComputer.psd1"
    $mergedSettings['destination_mac_address'] = $destinationSettings['mac_address']
    $mergedSettings['destination_root_path'] = $destinationSettings['destination_root_path']

    Write-Output "Initialized config:"
    Write-Output-HashTable -HashTable $mergedSettings

    return $mergedSettings
}
