# Common functionality across all versions of PowerShell
function Get-GitStatus { git status $args }
Set-Alias -Name gst -Value Get-GitStatus

function Open-SublimeFile { subl $args }
Set-Alias -Name st -Value Open-SublimeFile
