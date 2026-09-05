<#
.SYNOPSIS
    Manages machine configuration and related helpful commands
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet("up", "backup", "help", "-h", "--help", "/?")]
    [string]$Action,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$ExtraArgs
)

switch ($Action) {
    "up" {
        & chezmoi apply --override-data '{\"upgrade_software\": \"true\"}' @ExtraArgs
    }
    "backup" {
        Start-ScheduledTask -TaskName "Scott tasks\scruth-backup"
        Get-Content -Path "C:\Logs\MyTaskOutput.log" -Wait -Tail 10
    }
    { $_ -in "help", "-h", "--help", "/?" } {
        @'
Usage: scruth [<action>] [<args>]

Actions:
  up        Update machine state using chezmoi and install available winget upgrades
  backup    Runs scruth-backup using Task Scheduler
  help      Show this usage message

Default:
  Running 'scruth' with no action just updates bachine state using chezmoi and checks for available winget upgrades
'@
    }
    Default {
        & chezmoi apply @ExtraArgs
    }
}