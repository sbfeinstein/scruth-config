# Define Emoji Constants using Hex codes (PS 5.1 compatible)
# https://www.w3schools.com/charsets/ref_emoji.asp
#
# You can get the write hex code to use for a given single-character symbol via:
# "0x{0:X4}" -f [int][char]'•' # outputs 0x2022
# "0x{0:X4}" -f [int][char]'•' # outputs 0x2022
#
# For files being rendered by chezmoi, this can be included as a template.
# https://www.chezmoi.io/user-guide/templating/#using-chezmoitemplates
# e.g. (remomove the comments /* */ since they are here to prevent expansion)
# {{/* template "emoji_constants.ps1" . */}}
#
# It can also be directly Powershell-sourced into a ps1 script.
# In this case the relative path needs to be adjusted to be correct.
# . ".\chezmoi_config\src\windows\.chezmoitemplates\emoji_constants.ps1"

$ICON_INFO     = [char]::ConvertFromUtf32(0x2139) + [char]::ConvertFromUtf32(0xFE0F)
$ICON_CROSS    = [char]::ConvertFromUtf32(0x274C)
$ICON_CHECK    = [char]::ConvertFromUtf32(0x2705)
$ICON_MAGE     = [char]::ConvertFromUtf32(0x1F9D9)
$ICON_ROCKET   = [char]::ConvertFromUtf32(0x1F680)
$ICON_GLASSES  = [char]::ConvertFromUtf32(0x1F60E)
$ICON_TM       = [char]::ConvertFromUtf32(0x2122)
$ICON_WRENCH   = [char]::ConvertFromUtf32(0x1F527)
$ICON_WARNING  = [char]::ConvertFromUtf32(0x26A0) + [char]::ConvertFromUtf32(0xFE0F)

$UNICODE_BULLET = [char]::ConvertFromUtf32(0x2022)
$UNICODE_EMDASH = [char]::ConvertFromUtf32(0x2014)
