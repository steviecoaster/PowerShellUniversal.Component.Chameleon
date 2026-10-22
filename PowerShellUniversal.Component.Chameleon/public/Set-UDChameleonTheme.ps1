function Set-UDChameleonTheme {
    <#
    .SYNOPSIS
    Applies a theme to the current PSU app connection.

    .DESCRIPTION
    Wraps Set-UDTheme so the user's current light/dark mode is preserved (Set-UDTheme otherwise
    forces 'light'). Must be called from an endpoint (OnClick, OnChange, etc.).

    .PARAMETER Theme
    A theme hashtable, JSON string, or object.

    .PARAMETER Name
    The name of a built-in theme (see Get-UDTheme).

    .PARAMETER Variant
    light or dark. When omitted, the browser's current mode is used.

    .EXAMPLE
    New-UDButton -Text 'Dracula' -OnClick { Set-UDChameleonTheme -Name 'Dracula' }
    #>
    [CmdletBinding(DefaultParameterSetName = 'Theme')]
    param(
        [Parameter(Mandatory, ParameterSetName = 'Theme')]
        [object]$Theme,

        [Parameter(Mandatory, ParameterSetName = 'Name')]
        [string]$Name,

        [Parameter()]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Variant
    )

    if ($PSCmdlet.ParameterSetName -eq 'Name') {
        # Only accept known names; Get-UDTheme -Name builds a file path from it.
        if ($Name -cnotin @(Get-ChameleonBuiltInName) + @(Get-UDTheme)) {
            throw "Unknown built-in theme '$Name'."
        }
        $Hashtable = Get-UDTheme -Name $Name
    }
    else {
        $Hashtable = ConvertTo-UDChameleonHashtable -InputObject $Theme
    }

    if ($Variant -notin 'light', 'dark') {
        try {
            $Variant = [string](Get-UDTheme -Current)
        }
        catch {
            $Variant = $null
        }
    }
    if ($Variant -notin 'light', 'dark') {
        $Variant = 'light'
    }

    $SetTheme = @{
        Theme = $Hashtable
        Variant = $Variant.ToLower()
    }
    Set-UDTheme @SetTheme
}
