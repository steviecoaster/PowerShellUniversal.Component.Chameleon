@{
    RootModule        = 'PowerShellUniversal.Component.Chameleon.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '6f1d2c3e-8a47-4b5e-9c1a-2d7e4f0b9a31'
    Author            = 'Stephen Valdinger'
    CompanyName       = 'Unknown'
    Copyright         = '(c) 2026 Stephen Valdinger. All rights reserved.'
    Description       = 'Theme builder and theme picker components for PowerShell Universal apps, plus a Chameleon app for designing and managing MUI themes.'
    PowerShellVersion = '7.2'
    FunctionsToExport = @(
        'New-UDThemeBuilder'
        'New-UDThemePicker'
        'Set-UDChameleonTheme'
        'Get-UDChameleonTheme'
        'Save-UDChameleonTheme'
        'Remove-UDChameleonTheme'
        'ConvertTo-UDChameleonHashtable'
        'ConvertTo-UDChameleonSource'
        'New-UDChameleonApp'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags = @('PowerShellUniversal', 'UniversalDashboard', 'Theme', 'MUI')
        }
    }
}
