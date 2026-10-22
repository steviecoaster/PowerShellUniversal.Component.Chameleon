function Save-UDChameleonTheme {
    <#
    .SYNOPSIS
    Saves a theme to the theme store.

    .PARAMETER Name
    Theme name. Letters, numbers, spaces, '-', '_' and '.' only (max 64 characters).

    .PARAMETER Theme
    A theme hashtable, JSON string, or object.

    .PARAMETER Description
    Optional description shown as a tooltip in the theme picker.

    .PARAMETER Path
    Theme store folder. Defaults to $env:PSU_CHAMELEON_PATH, otherwise $env:ProgramData/Chameleon
    on Windows, or UniversalAutomation/Chameleon under the XDG data directory on Linux
    or ~/Library/Application Support on macOS.

    .EXAMPLE
    $SaveTheme = @{
        Name = 'Corporate'
        Theme = @{ palette = @{ primary = @{ main = '#0b5394' } } }
    }
    Save-UDChameleonTheme @SaveTheme
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Name,

        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [object]$Theme,

        [Parameter(ValueFromPipelineByPropertyName)]
        [string]$Description,

        [Parameter()]
        [string]$Path
    )

    process {
        $Name = $Name.Trim()
        Assert-ChameleonName -Name $Name

        $Store = Get-ChameleonStorePath -Path $Path -Create
        $File = Join-Path $Store "$Name.json"

        if (-not $PSBoundParameters.ContainsKey('Description') -and (Test-Path -LiteralPath $File)) {
            $Existing = Get-Content -LiteralPath $File -Raw | ConvertFrom-Json -AsHashtable -Depth 64
            $Description = $Existing.description
        }

        $Record = [ordered]@{
            name        = $Name
            description = $Description
            modified    = (Get-Date).ToUniversalTime().ToString('o')
            theme       = ConvertTo-UDChameleonHashtable -InputObject $Theme
        }

        if ($PSCmdlet.ShouldProcess($File, 'Save theme')) {
            $Record | ConvertTo-Json -Depth 64 | Set-Content -LiteralPath $File -Encoding utf8
            Get-UDChameleonTheme -Name ([WildcardPattern]::Escape($Name)) -Path $Store
        }
    }
}
