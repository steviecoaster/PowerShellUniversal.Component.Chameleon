# Chameleon app

$Pages = foreach ($PageFile in Get-ChildItem -Path "$PSScriptRoot\pages\*.ps1" | Sort-Object Name) {
    . $PageFile.FullName
    Get-Variable -Name $PageFile.BaseName -ValueOnly -ErrorAction SilentlyContinue
}

$App = @{
    Title = 'Chameleon'
    Pages = @($Pages)
    HeaderContent = {
        $Saved = @(Get-UDChameleonTheme)
        $Choices = if ($Saved.Count) { $Saved } else { @('AntDesign', 'Paperbase', 'Sand', 'Compliment') }
        New-UDThemePicker -Id 'chameleonHeaderPicker' -Themes $Choices
    }
}
New-UDApp @App
