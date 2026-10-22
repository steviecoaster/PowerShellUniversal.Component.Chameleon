function Get-ChameleonBuiltInName {
    # PSU's hand-made MUI themes. Get-UDTheme also lists ~290 terminal color schemes, which we skip.
    @('MaterialDesign', 'AntDesign', 'Paperbase', 'Sand', 'Compliment')
}

function Get-ChameleonStorePath {
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Path,

        [Parameter()]
        [switch]$Create
    )

    if (-not $Path) {
        $Path = if ($env:PSU_CHAMELEON_PATH) {
            $env:PSU_CHAMELEON_PATH
        }
        elseif ($IsWindows) {
            Join-Path $env:ProgramData 'Chameleon'
        }
        else {
            $DataRoot = if ($IsMacOS) {
                Join-Path $HOME 'Library' 'Application Support'
            }
            elseif ($env:XDG_DATA_HOME -and [System.IO.Path]::IsPathRooted($env:XDG_DATA_HOME)) {
                $env:XDG_DATA_HOME
            }
            else {
                Join-Path $HOME '.local' 'share'
            }
            Join-Path $DataRoot 'UniversalAutomation' 'Chameleon'
        }
    }

    if ($Create -and -not (Test-Path -LiteralPath $Path)) {
        $null = New-Item -Path $Path -ItemType Directory -Force
    }

    $Path
}

function Assert-ChameleonName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    # Names become file names, so restrict them to prevent path traversal.
    if ($Name -notmatch '^[A-Za-z0-9][A-Za-z0-9 _\-\.]{0,63}$' -or $Name -match '\.\.') {
        throw "Invalid theme name '$Name'. Use letters, numbers, spaces, '-', '_' or '.' (max 64 characters)."
    }
}

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
