$app = @{
    Name        = 'Chameleon'
    BaseUrl     = '/chameleon'
    Module      = 'PowerShellUniversal.Component.Chameleon'
    Command     = 'New-UDChameleonApp'
    AutoDeploy  = $true
    Description = 'Build MUI themes for PowerShell Universal apps and switch between them at runtime'
    Environment = 'Integrated'
    Authenticated = $false
}

New-PSUApp @app
