function ConvertTo-ChameleonPowerShellValue {
    [CmdletBinding()]
    param(
        [Parameter()]
        [AllowNull()]
        [object]$Value,

        [Parameter()]
        [int]$Depth = 0
    )

    $Pad = '    ' * ($Depth + 1)
    $End = '    ' * $Depth

    if ($null -eq $Value) {
        return '$null'
    }
    if ($Value -is [bool]) {
        if ($Value) {
            return '$true'
        }
        return '$false'
    }
    if ($Value -is [string]) {
        return "'" + $Value.Replace("'", "''") + "'"
    }
    if ($Value -is [System.Collections.IDictionary]) {
        $Keys = @($Value.Keys)
        if ($Keys.Count -eq 0) {
            return '@{}'
        }

        $Entries = foreach ($Key in $Keys) {
            $KeyText = [string]$Key
            if ($KeyText -notmatch '^[A-Za-z_][A-Za-z0-9_]*$') {
                $KeyText = "'" + $KeyText.Replace("'", "''") + "'"
            }
            "$Pad$KeyText = $(ConvertTo-ChameleonPowerShellValue -Value $Value[$Key] -Depth ($Depth + 1))"
        }
        return "@{`n$($Entries -join "`n")`n$End}"
    }
    if ($Value -is [System.Collections.IEnumerable]) {
        $Items = @($Value)
        if ($Items.Count -eq 0) {
            return '@()'
        }

        $Entries = foreach ($Item in $Items) {
            "$Pad$(ConvertTo-ChameleonPowerShellValue -Value $Item -Depth ($Depth + 1))"
        }
        return "@(`n$($Entries -join "`n")`n$End)"
    }
    if ($Value -is [System.IFormattable]) {
        return $Value.ToString($null, [System.Globalization.CultureInfo]::InvariantCulture)
    }

    "'" + ([string]$Value).Replace("'", "''") + "'"
}
