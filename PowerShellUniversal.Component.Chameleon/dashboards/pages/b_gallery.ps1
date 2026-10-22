$b_gallery = New-UDPage -Name 'Saved Themes' -Url '/themes' -Icon (New-UDIcon -Icon 'Palette') -Content {
    New-UDDynamic -Id 'chameleonGallery' -Content {
        $Saved = @(Get-UDChameleonTheme)

        if (-not $Saved.Count) {
            New-UDAlert -Severity info -Text 'No saved themes yet. Build one on the Builder page and click Save.'
            return
        }

        New-UDTypography -Text 'Click a theme to try it on this app.' -Variant body2
        New-UDThemePicker -Id 'chameleonGalleryPicker' -Themes $Saved -Variant grid

        $Columns = @(
            New-UDTableColumn -Property Name -Title 'Name'
            New-UDTableColumn -Property Modified -Title 'Modified (UTC)'
            New-UDTableColumn -Property Actions -Title 'Actions' -OnRender {
                $ThemeName = $EventData.Name
                New-UDStack -Direction row -Spacing 1 -Children {
                    New-UDButton -Text 'Edit' -Size small -Variant outlined -OnClick {
                        Invoke-UDRedirect -Url "/builder?theme=$([uri]::EscapeDataString($ThemeName))"
                    }
                    New-UDButton -Text 'Copy PowerShell' -Size small -Variant outlined -OnClick {
                        $Saved = Get-UDChameleonTheme -Name ([WildcardPattern]::Escape($ThemeName)) | Select-Object -First 1
                        $Json = $Saved.Theme | ConvertTo-Json -Depth 64
                        Set-UDClipboard -Data "`$Theme = '$($Json -replace "'", "''")' | ConvertFrom-Json -AsHashtable"
                        Show-UDToast -Message "Copied $ThemeName"
                    }
                    New-UDButton -Text 'Delete' -Size small -Variant outlined -Color error -OnClick {
                        Remove-UDChameleonTheme -Name $ThemeName -Confirm:$false
                        Show-UDToast -Message "Deleted $ThemeName"
                        Sync-UDElement -Id 'chameleonGallery'
                    }
                }
            }
        )

        $Table = @{
            Id = 'chameleonTable'
            Title = 'Saved themes'
            Data = @($Saved | Select-Object -Property Name, Modified)
            Columns = $Columns
            ShowPagination = $true
            PageSize = 10
        }
        New-UDTable @Table
    }
}
