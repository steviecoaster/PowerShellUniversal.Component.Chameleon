function Get-ChameleonSwatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [object]$Theme
    )

    $Hashtable = ConvertTo-UDChameleonHashtable -InputObject $Theme
    $Palette = if ($Hashtable.light -and $Hashtable.light.palette) {
        $Hashtable.light.palette
    }
    elseif ($Hashtable.palette) {
        $Hashtable.palette
    }
    elseif ($Hashtable.dark -and $Hashtable.dark.palette) {
        $Hashtable.dark.palette
    }
    else {
        @{}
    }

    $Background = if ($Palette.background) { $Palette.background.default } else { $null }
    $Paper = if ($Palette.background -and $Palette.background.paper) { $Palette.background.paper } else { $Background }

    @(
        if ($Palette.primary) { $Palette.primary.main } else { '#1976d2' }
        if ($Palette.secondary) { $Palette.secondary.main } else { '#9c27b0' }
        if ($Background) { $Background } else { '#ffffff' }
        if ($Paper) { $Paper } else { '#ffffff' }
    )
}
