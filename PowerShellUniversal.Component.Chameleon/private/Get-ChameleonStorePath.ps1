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
