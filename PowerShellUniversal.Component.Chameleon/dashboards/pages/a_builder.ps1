$a_builder = New-UDPage -Name 'Builder' -Url '/builder' -DefaultHomePage -Icon (New-UDIcon -Icon 'PaintBrush') -Content {
    New-UDThemeBuilder -Id 'chameleonBuilder'
}
