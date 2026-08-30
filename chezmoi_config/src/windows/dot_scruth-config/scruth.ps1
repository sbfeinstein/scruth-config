<#
.SYNOPSIS
    Manages machine configurations via chezmoi.
#>
param(
    [string]$Action
)

if ($Action -eq "up") {
    & chezmoi apply --override-data '{\"upgrade_software\": \"true\"}'
}
else {
    & chezmoi apply
}
