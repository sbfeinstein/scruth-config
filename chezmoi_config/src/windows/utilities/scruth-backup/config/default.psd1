@{
    # Destination device
    destination_computer = 'RARSTEENS'

    # Gmail OAuth2.0
    # https://console.cloud.google.com/auth/clients?invt=Aboc2g&project=personal-scripts-447101&supportedpurview=project
    gmail_oath_account = 'sbf1491@gmail.com'
    gmail_oauth_client_id = '659667676848-8kskl67te9opcm2uvqh4k88lqsjrtq89.apps.googleusercontent.com'
    gmail_oauth_client_secret_key_name = 'op://Scruth Automation/scruth-config/Secrets/Google - OAuth 2.0 Client ID - Scruth Backup Scripts - ClientSecret'
    gmail_oauth_from_name = 'Scott Feinstein'
    gmail_oauth_server = 'smtp.gmail.com'
    gmail_oauth_to_email = 'Scott_Feinstein@yahoo.com'

    ### Expected to be overriden by the config for the source device
    name = ''
    backup_tasks = @()
}
