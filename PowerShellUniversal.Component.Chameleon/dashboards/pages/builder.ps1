$a_builder = New-UDPage -Name 'Theme Builder' -Url '/builder' -DefaultHomePage -Icon (New-UDIcon -Icon 'PaintBrush') -Content {
    New-UDThemeBuilder -Id 'chameleonBuilder'
}
