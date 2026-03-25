. $PWD\utils\log-utils.ps1
. $PWD\utils\sync-utils.ps1

class BackupTask {
    [DateTime]$StartTimestamp
    [Nullable[DateTime]]$EndTimestamp
    [string]$SourceDrive
    [string]$SourceFilterFilePath
    [array]$SyncOutput
    [array]$ConfirmOutput

    BackupTask ([DateTime]$start, [Nullable[DateTime]]$end, [string]$drive, [string]$filterFilePath, [array]$syncOutput, [array]$confirmOutput) {
        $this.StartTimestamp = $start
        $this.EndTimestamp = $end
        $this.SourceDrive = $drive
        $this.SourceFilterFilePath = $filterFilePath
        $this.SyncOutput = $syncOutput
        $this.ConfirmOutput = $confirmOutput
    }

    [bool]HasSyncErrors() {
        foreach ($syncOutput in $this.SyncOutput) {
            if ($syncOutput.PSObject.Properties.Match("stats")) {
                if ($syncOutput.stats.errors -gt 0) {
                    return $true
                }
            }
        }
        return $false
    }

    [bool]HasConfirmErrors() {
        foreach ($confirmOutput in $this.ConfirmOutput) {
            if ($confirmOutput.PSObject.Properties.Match("stats")) {
                if ($confirmOutput.stats.errors -gt 0) {
                    return $true
                }
            }
        }
        return $false
    }
}

class BackupJob {
    [DateTime]$StartTimestamp
    [Nullable[DateTime]]$EndTimestamp
    [BackupTask[]]$Tasks

    BackupJob ([DateTime]$start, [Nullable[DateTime]]$end, [BackupTask[]]$tasks) {
        $this.StartTimestamp = $start
        $this.EndTimestamp = $end
        $this.Tasks = $tasks
    }

    [bool]HasSyncErrors() {
        foreach ($task in $this.Tasks) {
            if ($task.HasSyncErrors()) {
                return $true
            }
        }
        return $false
    }

    static [BackupJob]Reserialize([PSCustomObject]$deserializedJob) {
        $otasks = @()
        foreach ($task in $deserializedJob.Tasks) {
            $otasks += [BackupTask]::new(
                [DateTime]$task.StartTimestamp,
                [Nullable[DateTime]]$task.EndTimestamp,
                [string]$task.SourceDrive,
                [string]$task.SourceFilterFilePath,
                [array]$task.SyncOutput,
                [array]$task.ConfirmOutput
            )
        }
        return [BackupJob]::new(
            [DateTime]$deserializedJob.StartTimestamp,
            [Nullable[DateTime]]$deserializedJob.EndTimestamp,
            $otasks
        )
    }
}

function Invoke-Backup-Device {

    [OutputType([BackupJob])]
    param (
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    $sourceComputer = $Config['name']
    $job = [BackupJob]::new((Get-Date), $null, @())

    Write-Host "$(Get-TimeStampString) Starting synchronization of $sourceComputer"
    foreach ($task in $Config['backup_tasks']) {
        $sourceDrive = $task['SourceDrive']
        $filterFile = $task['FilterFile']

        $task = Invoke-Backup-Task -Config $Config -SourceComputer $sourceComputer -SourceDrive $sourceDrive -FilterFile $filterFile
        $job.tasks += $task
    }
    Write-Host "$(Get-TimeStampString) Finished synchronization of $sourceComputer"

    $job.EndTimestamp = (Get-Date)
    return $job
}

function Invoke-Backup-Task {

    [OutputType([BackupTask])]
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
  
    $task = [BackupTask]::new((Get-Date), $null, $SourceDrive, $FilterFile, $(), $())

    $syncOutputMultiJsonString = Sync-Dir -Config $Config -SourceComputer $SourceComputer -SourceDrive $SourceDrive -FilterFile $FilterFile

    foreach ($syncOutputJsonString in $syncOutputMultiJsonString) {
        $syncOutputObj = $syncOutputJsonString | ConvertFrom-Json
        $task.SyncOutput += $syncOutputObj
        Write-Host "level: $($syncOutputObj.level)"
        Write-Host "message:`n$($syncOutputObj.msg.Trim())"
        Write-Host "stats: $($syncOutputObj.stats | Format-List | Out-String)"
    }

    $confirmOutputMultiJsonString = Confirm-Synced-Dir -Config $Config -SourceComputer $SourceComputer -SourceDrive $SourceDrive -FilterFile $FilterFile
    
    $confirmOutputJsonStrings = $confirmOutputMultiJsonString -split "(?<=})\s*(?={)"
    foreach ($confirmOutputJsonString in $confirmOutputJsonStrings) {
        $confirmOutputObj = $confirmOutputJsonString | ConvertFrom-Json
        $task.ConfirmOutput += $confirmOutputObj
        Write-Host "level: $($confirmOutputObj.level)"
        Write-Host "message:`n$($confirmOutputObj.msg.Trim())"
        Write-Host "stats: $($confirmOutputObj.stats | Format-List | Out-String)"
    }

    $task.EndTimestamp = (Get-Date)
    return $task
}

