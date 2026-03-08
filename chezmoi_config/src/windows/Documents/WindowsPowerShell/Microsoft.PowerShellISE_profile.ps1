# Render unicode chars like emojis correctly in powershell consoles including ISE
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$OutputEncoding = [Console]::OutputEncoding

# Set the ISE Font to Consolas 16 pt
$psISE.Options.FontName = "Consolas"
$psISE.Options.FontSize = 14
