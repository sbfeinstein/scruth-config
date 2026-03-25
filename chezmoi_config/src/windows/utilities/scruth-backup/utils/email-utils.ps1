. $PWD\utils\job-utils.ps1
. $PWD\utils\log-utils.ps1
. $PWD\utils\secret-utils.ps1

function Send-JobReportEmail {
    param (
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [object]$BackupJob  # Changed from [BackupJob]
    )

    $body = Get-BackupEmailBody -Config $Config -BackupJob $BackupJob

    $statusTag = if ($BackupJob.HasSyncErrors()) { 'ERRORS' } else { 'SUCCESS' }
    $subject = "$(Get-TimeStampString): Email Backup - $($Config['name']) - $statusTag"

    Send-Email `
        -Config $Config `
        -Subject $subject `
        -Body $body
}

function Get-BackupEmailBody {
    param (
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [object]$BackupJob  # Changed from [BackupJob]
    )
    
    $sourceName = $($Config['name'])
    $duration = $BackupJob.EndTimestamp - $BackupJob.StartTimestamp
    $durationStr = "{0:h\:mm\:ss}" -f $duration

    # Build job overview table
    $jobOverview = @(
        [PSCustomObject]@{
            'Property' = 'Backup Source'
            'Value' = $sourceName
        },
        [PSCustomObject]@{
            'Property' = 'Start Time'
            'Value' = Get-TimeStampString($BackupJob.StartTimestamp)
        },
        [PSCustomObject]@{
            'Property' = 'End Time'
            'Value' = Get-TimeStampString($BackupJob.EndTimestamp)
        },
        [PSCustomObject]@{
            'Property' = 'Duration'
            'Value' = $durationStr
        }
    )

    # Build task summaries and details
    $taskSummaries = @()
    $taskDetails = @()

    foreach ($task in $BackupJob.Tasks) {
        # Find the last SyncOutput entry with non-zero stats
        $lastStats = $null
        if ($task.SyncOutput -and $task.SyncOutput.Count -gt 0) {
            # Look through all entries in reverse order to find last meaningful stats
            for ($i = $task.SyncOutput.Count - 1; $i -ge 0; $i--) {
                $stats = $task.SyncOutput[$i].stats
                if ($stats -and 
                    ($stats.transfers -gt 0 -or 
                     $stats.bytes -gt 0 -or 
                     $stats.errors -gt 0)) {
                    $lastStats = $stats
                    break
                }
            }
        }

        # If no meaningful stats found in SyncOutput, check ConfirmOutput
        if (-not $lastStats -and $task.ConfirmOutput -and $task.ConfirmOutput.Count -gt 0) {
            $lastStats = $task.ConfirmOutput[-1].stats
        }

        # Create one-line summary
        $summary = "$($task.SourceDrive): "
        if ($lastStats) {
            $bytesStr = if ($lastStats.bytes -gt 0) {
                [string]([Math]::Round($lastStats.bytes / 1GB, 2)) + " GB"
            } else { "0 B" }
            
            $summary += "$bytesStr transferred, $($lastStats.transfers) files, "
            $summary += if ($lastStats.errors -gt 0) {
                "$($lastStats.errors) errors"
            } else { "no errors" }
        } else {
            $summary += "No stats available"
        }

        $taskSummaries += $summary

        # Collect detailed information
        if ($lastStats) {
            $details = @()
            $details += "Transfer Statistics:"
            $details += " - Files: $($lastStats.transfers) / $($lastStats.totalTransfers)"
            $details += " - Checks: $($lastStats.checks) / $($lastStats.totalChecks)"
            $details += " - Data: $([Math]::Round($lastStats.bytes / 1MB, 2)) MB"
            
            if ($lastStats.errors -gt 0) {
                $details += ""
                $details += "Error Information:"
                $details += " - Count: $($lastStats.errors)"
                $details += " - Last Error: $($lastStats.lastError)"
            }

            # Collect transferred files from sync history - look at transferring entries across all sync outputs
            $transferredFiles = @()
            if ($task.SyncOutput) {
                # Start with the first entries to get files in order of transfer
                foreach ($sync in $task.SyncOutput) {
                    if ($sync.stats.transferring) {
                        foreach ($transfer in $sync.stats.transferring) {
                            $name = $transfer.MS.name
                            if ($name -and $transferredFiles -notcontains $name) {
                                # Clean up the path for readability
                                $displayName = $name -replace '^Users/scott/AppData/Roaming/', ''
                                $transferredFiles += $displayName
                            }
                        }
                    }
                }

                # If files were transferred but we didn't catch them in progress,
                # at least show the final count
                if ($lastStats.transfers -gt 0 -and $transferredFiles.Count -eq 0) {
                    $details += ""
                    $details += "Files Transferred: $($lastStats.transfers) files"
                }
                elseif ($transferredFiles.Count -gt 0) {
                    $details += ""
                    $details += "Files Processed During Backup:"
                    foreach ($file in ($transferredFiles | Sort-Object)) {
                        $details += " - $file"
                    }
                }
            }

            $taskDetails += @{
                Drive = $task.SourceDrive
                Details = $details
            }
        }
    }

    return EmailBody -FontFamily 'Calibri' -Size 15 {
        EmailText -Text 'Backup Report for ', $sourceName -Color None, Blue
        EmailText -LineBreak

        EmailTable -Table $jobOverview -HideFooter
        EmailText -LineBreak

        EmailText -Text 'Task Summaries:' -Color None, Black
        EmailTextBox {
            $taskSummaries
        }
        EmailText -LineBreak

        if ($BackupJob.HasSyncErrors()) {
            EmailText -Text 'Overall Status: ', 'Errors Detected' -Color None, Red
        }
        else {
            EmailText -Text 'Overall Status: ', 'Success' -Color None, Green
        }
        EmailText -LineBreak
        EmailText -LineBreak

        if ($taskDetails.Count -gt 0) {
            EmailText -Text 'Detailed Information:' -Color None, Black
            foreach ($detail in $taskDetails) {
                EmailText -Text "Drive $($detail.Drive):" -Color Blue
                EmailTextBox {
                    $detail.Details
                }
                EmailText -LineBreak
            }
        }

        EmailTextBox {
            'Kind regards,'
            'ScruthAdmin'
        }
    }
}

function Send-TestEmail {
    param (
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory = $false)] 
        [Switch]$SampleData
    )

    $body = EmailBody {
        EmailText -Text 'Test email.'
    }

    $statusTag = 'SUCCESS'
    if ($SampleData) {
        $deserializedSampleJob = Import-Clixml -Path "$PWD/resources/example_data/output_example_errors_1.xml"
        $deserializedSampleJob = [PSCustomObject]$deserializedSampleJob
        $sampleJob = [BackupJob]::Reserialize($deserializedSampleJob)
        $body = Get-BackupEmailBody -Config $Config -BackupJob $sampleJob
        $statusTag = if ($sampleJob.HasSyncErrors()) { 'ERRORS' } else { 'SUCCESS' }
    }

    $subject = "$(Get-TimeStampString): Email Backup - Test Email - $($Config['name']) - $statusTag"

    Send-Email `
        -Config $Config `
        -Subject $subject `
        -Body $body
}

function Send-Email {
    param (
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [string]$Subject,

        [Parameter(Mandatory)]
        [string]$Body
    )

    $fromName = $Config['gmail_oauth_from_name']
    $fromEmail = $Config['gmail_oath_account']
    $toEmail = $Config['gmail_oauth_to_email']
    $oauthServer = $Config['gmail_oauth_server']
    $clientID = $Config['gmail_oauth_client_id']
    $clientSecretKey = $Config['gmail_oauth_client_secret_key_name']
    $clientSecret = Get-SecretPlainText -Config $Config -Name $clientSecretKey

    $maxRetries = 3
    $retryCount = 0
    $success = $false

    while (-not $success -and $retryCount -lt $maxRetries) {
        try {
            $CredentialOAuth2 = Connect-oAuthGoogle `
                -ClientID $clientID `
                -ClientSecret $clientSecret `
                -GmailAccount $fromEmail

            Send-EmailMessage `
                -From @{
                Name  = $fromName
                Email = $fromEmail
            } `
                -To $toEmail `
                -Server $oauthServer `
                -HTML $Body `
                -Priority High `
                -Subject $Subject `
                -SecureSocketOptions Auto `
                -Credential $CredentialOAuth2 `
                -oAuth

            $success = $true
        }
        catch {
            $retryCount++
            if ($retryCount -lt $maxRetries) {
                Write-Warning "Email send attempt $retryCount failed. Retrying in 3 seconds..."
                Start-Sleep -Seconds 3
            }
            else {
                Write-Error "Failed to send email after $maxRetries attempts: $_"
                throw
            }
        }
    }
}
