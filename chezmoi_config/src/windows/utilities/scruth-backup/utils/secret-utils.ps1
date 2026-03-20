. $PWD\utils\log-utils.ps1

function Get-SecretPlainText {

    param (
        [Parameter(Mandatory)]
        [hashtable]$Config,

        [Parameter(Mandatory)]
        [string]$Name
    )

    return op read $Name
}
