$test_secret = op read "op://Scruth Automation/scruth-config/Secrets/Test Secret"
$content = "$((Get-Date -Format 'MM/dd/yyyy h:mm:ss tt zzz')) `"scruth-config.Test Secret`": `"$test_secret`""

Write-Host $content
Add-Content -Path C:\Users\scott\Desktop\scruth-backup-log.txt -Value $content
