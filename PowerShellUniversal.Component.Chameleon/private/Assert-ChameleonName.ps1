function Assert-ChameleonName {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    # Names become file names, so restrict them to prevent path traversal.
    if ($Name -notmatch '^[A-Za-z0-9][A-Za-z0-9 _\-\.]{0,63}$' -or $Name -match '\.\.') {
        throw "Invalid theme name '$Name'. Use letters, numbers, spaces, '-', '_' or '.' (max 64 characters)."
    }
}
