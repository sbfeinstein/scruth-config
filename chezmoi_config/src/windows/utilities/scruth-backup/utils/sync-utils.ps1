# Define the common parameters 
$CommonParams = @(
    '${SourceDrive}:\',
    '$($Config["destination_root_path"])\$SourceComputer\$SourceDrive\',
    '--use-json-log',
    '--skip-links',
    '--stats-log-level',
    'NOTICE',
    '--filter-from',
    'resources\source_devices\$SourceComputer\$FilterFile'
)

Write-Host "rclone command is $rcloneExec"

function Sync-Dir {

    param (
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [string]$SourceComputer,
  
        [Parameter(Mandatory)]
        [string]$SourceDrive,
  
        [Parameter(Mandatory)]
        [string]$FilterFile
    )
    $rcloneExec = $Config['rclone_exec_path']
    $expandedParams = $CommonParams | ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString("$_") }
  
    Write-Host ("-" * 50)
    Write-Host "Syncing $SourceComputer, $SourceDrive drive using $FilterFile"
    Write-Host "Rclone Parameters:`n  $expandedParams`n"
  
    & $rcloneExec sync `
        $expandedParams `
        2>&1 `
    | Select-String -Pattern (Get-Content resources/rclone/patterns-for-output.txt)
}

function Confirm-Synced-Dir {

    param (
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [string]$SourceComputer,
  
        [Parameter(Mandatory)]
        [string]$SourceDrive,
  
        [Parameter(Mandatory)]
        [string]$FilterFile
    )

    $rcloneExec = $Config['rclone_exec_path']
    $expandedParams = $CommonParams | ForEach-Object { $ExecutionContext.InvokeCommand.ExpandString("$_") }
  
    Write-Host ("-" * 50)
    Write-Host "Validating $SourceComputer, $SourceDrive drive using $FilterFile"
    Write-Host "Rclone Parameters:`n  $expandedParams`n"
  
    $out = & $rcloneExec check `
        $expandedParams `
        --size-only `
        --one-way `
        2>&1 `
    
    return $out | Select-String -Pattern (Get-Content resources/rclone/patterns-for-output.txt)
}
