function New-UDChameleonApp {
    <#
    .SYNOPSIS
    Creates the Chameleon app for designing and managing themes.

    .EXAMPLE
    New-PSUApp -Name 'Chameleon' -BaseUrl '/chameleon' -Module 'PowerShellUniversal.Component.Chameleon' -Command 'New-UDChameleonApp'
    #>
    [CmdletBinding()]
    param()

    $Module = Get-Module -Name 'PowerShellUniversal.Component.Chameleon'
    if (-not $Module) {
        throw 'PowerShellUniversal.Component.Chameleon module is not loaded'
    }

    $AppScript = Join-Path $Module.ModuleBase 'dashboards\App.ps1'
    if (-not (Test-Path -LiteralPath $AppScript)) {
        throw "App script not found at: $AppScript"
    }

    & $AppScript
}
