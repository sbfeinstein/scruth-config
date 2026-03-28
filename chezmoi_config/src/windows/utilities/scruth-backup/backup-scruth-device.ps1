# Command line parameters
param(
  [ValidateSet("CRAFTINGISSEXY", "FAMILYFUN", "RARSTEENS")]
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

$output = Invoke-Backup-Device -Config $config
Send-JobReportEmail -Config $config -BackupJob $output
