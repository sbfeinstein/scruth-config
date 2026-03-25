function Ping-Destination {

    param (
        [Parameter(Mandatory)]
        [hashtable]$Config
    )

    $destinationPath = $Config['destination_root_path']
    $destinationMAC = $Config['destination_mac_address']

    Write-Output "Checking if backup destination is reachable"
    $isAwake = Test-NetworkPath -path $destinationPath
    $attempts = 1
    $maxAttempts = 3

    while (!$isAwake -and $attempts -le $maxAttempts) {
        Write-Output "Backup destination not reachable (attempt $attempts), sending magic packet and waiting 5 seconds"
        Send-MagicPacket -MacAddress $destinationMAC
        Start-Sleep -Seconds 5
        $attempts++
        $isAwake = Test-NetworkPath -path $destinationPath
    }

    if ($isAwake) {
        Write-Output "Backup destination is reachable"
        return $true
    } else {
        Write-Output "Backup destination is not reachable"
        return $false
    }    
}

function Test-NetworkPath {
    param (
        [string]$Path
    )
    if (Test-Path $Path) {
        return $true
    } else {
        return $false
    }
}

function Send-MagicPacket {

  param (
    [string]$MacAddress
  )

  $macByteArray = $MacAddress -split "[:-]" | ForEach-Object { [Byte] "0x$_"}
  [Byte[]] $magicPacket = (,0xFF * 6) + ($macByteArray * 16)
  $udpClient = New-Object System.Net.Sockets.UdpClient
  $udpClient.Connect(([System.Net.IPAddress]::Broadcast),7)
  $udpClient.Send($magicPacket,$magicPacket.Length) | Out-Null
  $udpClient.Close()
}
