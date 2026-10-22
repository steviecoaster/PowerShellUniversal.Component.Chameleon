function Get-UDChameleonTheme {
    <#
    .SYNOPSIS
    Returns themes saved with the theme builder.

    .PARAMETER Name
    Name of a saved theme. Supports wildcards. Returns all themes when omitted.

    .PARAMETER Path
    Theme store folder. Defaults to $env:PSU_CHAMELEON_PATH or <ProgramData>\UniversalAutomation\Chameleon.

    .EXAMPLE
    New-UDApp -Title 'My App' -Theme (Get-UDChameleonTheme -Name 'Corporate').Theme -Content { }

    .EXAMPLE
    New-UDThemePicker -Themes (Get-UDChameleonTheme)
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [SupportsWildcards()]
        [string]$Name = '*',

        [Parameter()]
        [string]$Path
    )

    $Store = Get-ChameleonStorePath -Path $Path
    if (-not (Test-Path -LiteralPath $Store)) {
        return
    }

    Get-ChildItem -LiteralPath $Store -Filter '*.json' -File |
        Sort-Object -Property BaseName |
        ForEach-Object {
            try {
                $Data = Get-Content -LiteralPath $_.FullName -Raw | ConvertFrom-Json -AsHashtable -Depth 64
            }
            catch {
                Write-Warning "Skipping unreadable theme file '$($_.FullName)': $_"
                return
            }

            $ThemeName = if ($Data.name) { $Data.name } else { $_.BaseName }
            if ($ThemeName -notlike $Name) {
                return
            }

            [pscustomobject]@{
                PSTypeName  = 'Chameleon.Theme'
                Name        = $ThemeName
                Description = $Data.description
                Modified    = $Data.modified
                Theme       = $Data.theme
                Path        = $_.FullName
            }
        }
}
