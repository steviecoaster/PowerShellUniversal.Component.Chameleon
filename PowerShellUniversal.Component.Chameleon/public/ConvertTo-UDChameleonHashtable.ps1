function ConvertTo-UDChameleonHashtable {
    <#
    .SYNOPSIS
    Converts theme data (JSON string, PSCustomObject, or dictionary) into a hashtable.

    .DESCRIPTION
    Endpoint $EventData and stored themes can arrive in several shapes. This normalizes them
    into a hashtable suitable for Set-UDTheme and New-UDApp -Theme.

    .EXAMPLE
    $Data = ConvertTo-UDChameleonHashtable -InputObject $EventData
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [AllowNull()]
        [AllowEmptyString()]
        [object]$InputObject
    )

    process {
        if ($null -eq $InputObject) {
            return @{}
        }

        if ($InputObject -is [string]) {
            if ([string]::IsNullOrWhiteSpace($InputObject)) {
                return @{}
            }
            return $InputObject | ConvertFrom-Json -AsHashtable -Depth 64
        }

        if ($InputObject -is [hashtable]) {
            return $InputObject
        }

        # Newtonsoft JObject and similar types serialize back to JSON via ToString().
        if ($InputObject.GetType().FullName -like 'Newtonsoft.Json.Linq.*') {
            return $InputObject.ToString() | ConvertFrom-Json -AsHashtable -Depth 64
        }

        $InputObject | ConvertTo-Json -Depth 64 -Compress | ConvertFrom-Json -AsHashtable -Depth 64
    }
}
