function ConvertTo-UDChameleonSource {
    <#
    .SYNOPSIS
    Resolves a theme builder source ('saved:<name>' or 'builtin:<name>') to a JSON payload.

    .DESCRIPTION
    Used by the theme builder's "Start from" list. Returns JSON with name, label and theme,
    or nothing when the source is unknown.

    .EXAMPLE
    ConvertTo-UDChameleonSource -Source 'builtin:Paperbase'
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Source
    )

    $Kind, $Name = $Source -split ':', 2
    if (-not $Name) {
        return
    }

    $Result = switch ($Kind) {
        'saved' {
            $Saved = Get-UDChameleonTheme -Name ([WildcardPattern]::Escape($Name)) | Select-Object -First 1
            if ($Saved) {
                @{ name = $Saved.Name; label = $Saved.Name; theme = $Saved.Theme }
            }
        }
        'builtin' {
            # Only accept known names; Get-UDTheme -Name builds a file path from it.
            if ($Name -cin @(Get-ChameleonBuiltInName)) {
                $Base = ($Name -replace '[^A-Za-z0-9 _\-\.]', '').Trim()
                @{
                    name  = $Base.Substring(0, [Math]::Min(56, $Base.Length)) + ' Custom'
                    label = $Name
                    theme = Get-UDTheme -Name $Name
                }
            }
        }
    }

    if ($Result) {
        $Result | ConvertTo-Json -Depth 64 -Compress
    }
}
