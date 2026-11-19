# Chameleon app

$Pages = foreach ($PageFile in Get-ChildItem -Path "$PSScriptRoot\pages\*.ps1" | Sort-Object Name) {
    . $PageFile.FullName
    Get-Variable -Name $PageFile.BaseName -ValueOnly -ErrorAction Stop
}

$App = @{
    Title = 'Chameleon'
    Pages = @($Pages)
    HeaderContent = {
        New-UDThemePicker -Id 'chameleonHeaderPicker'
    }
}
New-UDApp @App
