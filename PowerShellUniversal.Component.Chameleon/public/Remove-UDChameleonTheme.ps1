function Remove-UDChameleonTheme {
    <#
    .SYNOPSIS
    Removes a saved theme from the theme store.

    .EXAMPLE
    Remove-UDChameleonTheme -Name 'Corporate' -Confirm:$false
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Name,

        [Parameter()]
        [string]$Path
    )

    process {
        Assert-ChameleonName -Name $Name
        $File = Join-Path (Get-ChameleonStorePath -Path $Path) "$Name.json"

        if (-not (Test-Path -LiteralPath $File)) {
            Write-Error "Theme '$Name' was not found."
            return
        }

        if ($PSCmdlet.ShouldProcess($File, 'Remove theme')) {
            Remove-Item -LiteralPath $File
        }
    }
}
