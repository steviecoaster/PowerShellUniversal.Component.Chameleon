BeforeAll {
    $AppScript = Join-Path $PSScriptRoot '..\PowerShellUniversal.Component.Chameleon\dashboards\App.ps1'

    function New-UDIcon {
        param($Icon)
        $Icon
    }

    function New-UDPage {
        param($Name, $Url, [switch]$DefaultHomePage, $Icon, [scriptblock]$Content)
        [pscustomobject]@{
            Name = $Name
            Url = $Url
            DefaultHomePage = $DefaultHomePage.IsPresent
            Icon = $Icon
            Content = $Content
        }
    }

    function New-UDApp {
        param($Title, $Pages, [scriptblock]$HeaderContent)
        [pscustomobject]@{
            Title = $Title
            Pages = $Pages
            HeaderContent = $HeaderContent
        }
    }
}

Describe 'Chameleon app page loading' {
    It 'loads both pages with the builder as the default home page' {
        $App = & $AppScript

        $App.Title | Should -Be 'Chameleon'
        $App.Pages.Count | Should -Be 2
        $App.Pages[0].Name | Should -Be 'Theme Builder'
        $App.Pages[0].Url | Should -Be '/builder'
        $App.Pages[0].DefaultHomePage | Should -BeTrue
        $App.Pages[0].Content | Should -BeOfType ([scriptblock])
        $App.Pages[1].Name | Should -Be 'Saved Themes'
        $App.Pages[1].Url | Should -Be '/themes'
        $App.Pages[1].DefaultHomePage | Should -BeFalse
        $App.Pages[1].Content | Should -BeOfType ([scriptblock])
        $App.HeaderContent | Should -BeOfType ([scriptblock])
    }

    It 'reports a page variable that does not match its filename' {
        Copy-Item -LiteralPath $AppScript -Destination $TestDrive
        $PagesPath = New-Item -Path (Join-Path $TestDrive 'pages') -ItemType Directory
        Set-Content -LiteralPath (Join-Path $PagesPath.FullName 'missing.ps1') -Value '$oldName = New-UDPage -Name Broken -Url /broken'

        { & (Join-Path $TestDrive 'App.ps1') } | Should -Throw '*missing*'
    }
}
