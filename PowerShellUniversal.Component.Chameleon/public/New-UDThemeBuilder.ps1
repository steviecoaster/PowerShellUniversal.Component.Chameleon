function New-UDThemeBuilder {
    <#
    .SYNOPSIS
    Creates an interactive MUI theme builder.

    .DESCRIPTION
    Edits light and dark palettes, typography and shape with a live preview. Themes can be applied to
    the running app, saved to the theme store, or copied as PowerShell / JSON for New-UDApp -Theme.

    .PARAMETER Id
    Component ID.

    .PARAMETER Name
    Initial theme name shown in the name box.

    .PARAMETER Theme
    Starting theme: hashtable, JSON string, Get-UDChameleonTheme result, or Get-UDTheme -Name output.

    .PARAMETER OnSave
    Called when Save is clicked. $EventData has 'name' and 'theme' (JSON string). Defaults to
    Save-UDChameleonTheme. Use ConvertTo-UDChameleonHashtable to work with the theme.

    .PARAMETER DisableSave
    Hides the Save button.

    .PARAMETER DisableApply
    Hides the Apply / Live / Reset controls.

    .PARAMETER HideStartFrom
    Hides the "Start from" list of saved and built-in themes.

    .EXAMPLE
    New-UDThemeBuilder -Id 'builder'

    .EXAMPLE
    $Builder = @{
        Name = 'Corporate'
        Theme = (Get-UDChameleonTheme -Name 'Corporate').Theme
        OnSave = { Show-UDToast -Message "Saved $($EventData.name)" }
    }
    New-UDThemeBuilder @Builder
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Id = (New-Guid).ToString(),

        [Parameter()]
        [string]$Name,

        [Parameter()]
        [object]$Theme,

        [Parameter()]
        [Endpoint]$OnSave,

        [Parameter()]
        [switch]$DisableSave,

        [Parameter()]
        [switch]$DisableApply,

        [Parameter()]
        [switch]$HideStartFrom
    )

    if ($Theme -and $Theme.PSObject.Properties['Theme'] -and $Theme.PSObject.Properties['Name']) {
        if (-not $Name) {
            $Name = $Theme.Name
        }
        $Theme = $Theme.Theme
    }

    $ThemeJson = if ($null -eq $Theme) {
        $null
    }
    elseif ($Theme -is [string]) {
        $Theme
    }
    else {
        $Theme | ConvertTo-Json -Depth 64 -Compress
    }

    $Save = $null
    if (-not $DisableSave) {
        $Save = if ($OnSave) {
            $OnSave
        }
        else {
            [Endpoint]::new({
                    $Data = ConvertTo-UDChameleonHashtable -InputObject $EventData
                    $null = Save-UDChameleonTheme -Name $Data.name -Theme $Data.theme
                })
        }
        $Save.Register($Id + 'onSave', $PSCmdlet)
    }

    $Apply = $null
    $Reset = $null
    if (-not $DisableApply) {
        $Apply = [Endpoint]::new({
                $Data = ConvertTo-UDChameleonHashtable -InputObject $EventData
                Set-UDChameleonTheme -Theme $Data.theme -Variant $Data.variant
            })
        $Apply.Register($Id + 'onApply', $PSCmdlet)

        $Reset = [Endpoint]::new({ Reset-UDTheme })
        $Reset.Register($Id + 'onReset', $PSCmdlet)
    }

    $Sources = @()
    $Load = $null
    if (-not $HideStartFrom) {
        $Sources = @(
            foreach ($Saved in Get-UDChameleonTheme) {
                @{ value = "saved:$($Saved.Name)"; label = $Saved.Name; group = 'Saved' }
            }
            foreach ($BuiltIn in Get-ChameleonBuiltInName) {
                @{ value = "builtin:$BuiltIn"; label = $BuiltIn; group = 'Built-in' }
            }
        )

        # Endpoint output isn't returned to the browser, so push the result back with Set-UDElement.
        $Load = [Endpoint]::new({
                $Data = ConvertTo-UDChameleonHashtable -InputObject $EventData
                $Result = @{
                    nonce   = [string]$Data.nonce
                    payload = ConvertTo-UDChameleonSource -Source ([string]$Data.source)
                }
                Set-UDElement -Id ([string]$Data.id) -Properties @{ loadResult = $Result }
            })
        $Load.Register($Id + 'onLoad', $PSCmdlet)
    }

    @{
        assetId  = $Script:AssetId
        isPlugin = $true
        type     = 'ud-theme-builder'
        id       = $Id
        name     = $Name
        theme    = $ThemeJson
        sources  = $Sources
        onSave   = $Save
        onApply  = $Apply
        onReset  = $Reset
        onLoad   = $Load
    }
}
