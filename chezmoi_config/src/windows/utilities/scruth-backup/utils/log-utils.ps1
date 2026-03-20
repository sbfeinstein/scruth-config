function Get-TimeStampString {    
    param (
        [DateTime]$Timestamp = (Get-Date)
    )

    $timeZone = $Timestamp.ToString("zzz")  # Time zone offset in +/-hh:mm format

    return "[{0:MM/dd/yy} {0:hh:mm:ss tt} UTC{1}]" -f $Timestamp, $timeZone
}

# Function to print hash table entries recursively and handle lists of objects
function Write-Host-HashTable {
    param (
        [hashtable]$HashTable,
        [string]$Indent = "  "
    )

    foreach ($key in $HashTable.Keys) {
        $value = $HashTable[$key]
        if ($value -is [hashtable]) {
            Write-Host "${Indent}${key}:"
            Write-Host-HashTable -HashTable $value -Indent "  $Indent"
        } elseif ($value -is [System.Collections.IList]) {
            Write-Host "$Indent$key (List):"
            $value | ForEach-Object {
                if ($_ -is [hashtable]) {
                    Write-Host "$Indent  - Item:"
                    Write-Host-HashTable -HashTable $_ -Indent "    $Indent"
                } else {
                    Write-Host "$Indent  - $_"
                }
            }
        } else {
            Write-Host "${Indent}${key}: $value"
        }
    }
}
