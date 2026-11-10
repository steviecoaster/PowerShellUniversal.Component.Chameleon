function ConvertTo-UDChameleonPowerShell {
    <#
    .SYNOPSIS
    Converts theme data into a PowerShell hashtable assignment.

    .PARAMETER Theme
    A theme hashtable, JSON string, or object.

    .EXAMPLE
    ConvertTo-UDChameleonPowerShell -Theme (Get-UDChameleonTheme -Name 'Corporate').Theme
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [object]$Theme
    )

    $Hashtable = ConvertTo-UDChameleonHashtable -InputObject $Theme
    '$Theme = ' + (ConvertTo-ChameleonPowerShellValue -Value $Hashtable)
}
