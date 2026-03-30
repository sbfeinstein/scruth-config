param(
  [ValidateSet("CraftingIsSexy", "FAMILYFUN", "RARSTEENS")]
  [Parameter(Mandatory = $true, HelpMessage = "Specify the computer name.")] 
  [string]$ComputerParam,

  [Parameter(Mandatory = $false, HelpMessage = "Sends an email, which is useful for re-validating OAuth2")] 
  [Switch]$EmailTestOnly,

  [Parameter(Mandatory = $false, HelpMessage = "Only relevant to -EmailTestOnly. If specified, the email will contain sample data.")] 
  [Switch]$SampleData 
)

. $PWD\config\config-init.ps1
$config = Initialize-Config($ComputerParam)
Write-Host "Initialized config:"
Write-Host-HashTable -HashTable $config

. $PWD\utils\email-utils.ps1
. $PWD\utils\wake-utils.ps1
. $PWD\utils\job-utils.ps1

if ($EmailTestOnly) {
  if ($SampleData) {
    Send-TestEmail -Config $config -SampleData
  } else {
    Send-TestEmail -Config $config
  }
  return
}

if (!(Ping-Destination -Config $config)) {
  throw 'Aborting due to unreachable backup destination'
}

# Export existing scheduled tasks so they can be backed up
# If we have more cases like this in the future, refactor to a pre-backup hook or similar.
$taskSchedulerPath = '\Scott tasks\'
$exportPath = "$HOME\.scruth-config\exported-scott-scheduled-tasks.xml"
Write-Host "Exporting '$taskSchedulerPath' from Task Scheduler, to $exportPath"
Get-ScheduledTask -TaskPath $taskSchedulerPath | Export-ScheduledTask | Out-File -FilePath $exportPath -Encoding UTF8
Write-Host "Done exporting '$taskSchedulerPath' from Task Scheduler, to $exportPath"

$output = Invoke-Backup-Device -Config $config
Send-JobReportEmail -Config $config -BackupJob $output
