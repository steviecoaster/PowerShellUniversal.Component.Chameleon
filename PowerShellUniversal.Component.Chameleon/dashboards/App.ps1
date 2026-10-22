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
        # Keep built-ins available after saving custom themes. Saved names take precedence
        # because the picker uses theme names as selection keys.
        $Choices = @($Saved) + @(
            Get-UDTheme |
                Where-Object { $_ -notin $Saved.Name }
        )
        New-UDThemePicker -Id 'chameleonHeaderPicker' -Themes $Choices
    }
}
New-UDApp @App
