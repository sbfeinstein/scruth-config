# scruth-backup
A home-grown utility that supports backing up files from **_ScruthSystems_** ™️.  It currently only supports Windows.

# Installation
`scruth-backup` is automatically installed by `scruth-config` (for all Windows systems), including the creation of a 
Task Scheduler job to run the backup.

# Rclone
[Rclone](https://rclone.org/) is used to synchronize files between computers and eventually will be used to synchronize backups to the cloud for additional protection.

Example command:

```
rclone sync `
  D:\ `
  \\Rarsteens\e-backup\backups\FAMILYFUN\D\ `
  --ignore-existing `
  --ignore-case `
  --skip-links `
  --stats-log-level NOTICE `
  --filter-from \Users\scott\utilities\scruth-backup\source_devices\FAMILYFUN\D-source-filter.txt `
  --dry-run `
  --log-file out.txt
```

# Modules dependencies
These are installed by `scruth-config` but pointed out for visibility.

- https://github.com/EvotecIT/Mailozaurr

      Install-Module -Name Mailozaurr -AllowClobber -Force

# Historical information
In the original, standalone version of this project (before `scruth-config`), secrets were managed via the 
[Microsoft.PowerShell.SecretManagement Module](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.secretmanagement/?view=ps-modules).

It is a secure and handy mechanism but in the `scruth-config` version of `scruth-backup` we opted to switch to a 
1password Service Account, with an encrypted Service Account Token that is only made available to the running backup
script.  The token allows the script to use the 1password CLI to retrieve secrets in memory and is scoped to just the
secrets required for the job.
