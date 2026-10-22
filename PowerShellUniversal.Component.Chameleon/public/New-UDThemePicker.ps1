function New-UDThemePicker {
    <#
    .SYNOPSIS
    Creates a theme picker that switches the app theme at runtime.

    .DESCRIPTION
    Lets users choose between themes. The selection is applied with Set-UDTheme for the user's
    connection, keeps their light/dark mode, and is remembered in the browser.

    .PARAMETER Id
    Component ID.

    .PARAMETER Themes
    Themes to offer. Accepts any mix of:
    - Built-in theme names (strings from Get-UDTheme)
    - Get-UDChameleonTheme results
    - Hashtables/objects with Name and Theme (and optional Description, Colors)
    - A single hashtable of name = theme pairs

    .PARAMETER Variant
    menu (dropdown button, good for -HeaderContent), grid (swatch cards) or select (native dropdown).

    .PARAMETER Label
    Button/select label shown when no theme is selected.

    .PARAMETER HideReset
    Hides the "Default" option that restores the app's configured theme.

    .PARAMETER StorageKey
    Browser storage key used to remember the selection. Defaults to the app's base URL segment.

    .PARAMETER OnChange
    Called after a theme is applied. $EventData is the selected theme name ('' for Default).

    .EXAMPLE
    New-UDApp -Title 'My App' -HeaderContent { New-UDThemePicker -Themes 'Dracula', 'nord', 'Github' } -Content { }

    .EXAMPLE
    $Picker = @{
        Themes = Get-UDChameleonTheme
        Variant = 'grid'
        OnChange = { Show-UDToast -Message "Theme: $EventData" }
    }
    New-UDThemePicker @Picker
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Id = (New-Guid).ToString(),

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [object[]]$Themes,

        [Parameter()]
        [ValidateSet('menu', 'grid', 'select')]
        [string]$Variant = 'menu',

        [Parameter()]
        [string]$Label = 'Theme',

        [Parameter()]
        [switch]$HideReset,

        [Parameter()]
        [string]$StorageKey,

        [Parameter()]
        [Endpoint]$OnChange
    )

    $Items = @(
        if ($Themes.Count -eq 1 -and $Themes[0] -is [System.Collections.IDictionary] -and -not $Themes[0].Contains('Name')) {
            foreach ($Key in $Themes[0].Keys) {
                @{ Name = [string]$Key; Theme = $Themes[0][$Key] }
            }
        }
        else {
            $Themes
        }
    )

    $BuiltIn = $null
    $Options = foreach ($Item in $Items) {
        if ($null -eq $Item) {
            continue
        }

        if ($Item -is [string]) {
            if ($null -eq $BuiltIn) {
                $BuiltIn = @(Get-ChameleonBuiltInName) + @(Get-UDTheme)
            }
            if ($Item -cnotin $BuiltIn) {
                Write-Warning "Skipping unknown built-in theme '$Item'."
                continue
            }
            @{
                name    = $Item
                builtin = $true
                colors  = @(Get-ChameleonSwatch -Theme (Get-UDTheme -Name $Item))
            }
            continue
        }

        $Record = if ($Item -is [System.Collections.IDictionary]) { $Item } else { ConvertTo-UDChameleonHashtable -InputObject $Item }
        $ThemeName = $Record['Name']
        if (-not $ThemeName) {
            Write-Warning 'Skipping theme without a Name.'
            continue
        }

        $Hashtable = ConvertTo-UDChameleonHashtable -InputObject $Record['Theme']
        @{
            name        = [string]$ThemeName
            description = $Record['Description']
            theme       = $Hashtable
            colors      = if ($Record['Colors']) { @($Record['Colors']) } else { @(Get-ChameleonSwatch -Theme $Hashtable) }
        }
    }

    $Apply = [Endpoint]::new({
            $Data = ConvertTo-UDChameleonHashtable -InputObject $EventData
            if ($Data.builtin) {
                Set-UDChameleonTheme -Name $Data.name -Variant $Data.variant
            }
            else {
                Set-UDChameleonTheme -Theme $Data.theme -Variant $Data.variant
            }
        })
    $Apply.Register($Id + 'onApply', $PSCmdlet)

    $Reset = [Endpoint]::new({ Reset-UDTheme })
    $Reset.Register($Id + 'onReset', $PSCmdlet)

    if ($OnChange) {
        $OnChange.Register($Id + 'onChange', $PSCmdlet)
    }

    @{
        assetId    = $Script:AssetId
        isPlugin   = $true
        type       = 'ud-theme-picker'
        id         = $Id
        themes     = @($Options)
        variant    = $Variant
        label      = $Label
        showReset  = -not $HideReset
        storageKey = $StorageKey
        onApply    = $Apply
        onReset    = $Reset
        onChange   = $OnChange
    }
}
