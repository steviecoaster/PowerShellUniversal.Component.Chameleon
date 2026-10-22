# Register the component bundle with PSU. Guarded because the module can be imported
# outside of a PSU host where the UniversalDashboard types aren't loaded.
$Script:AssetId = $null
try {
    $null = [UniversalDashboard.Services.AssetService]

    $assets = @(
        Get-ChildItem -Path $PSScriptRoot -Filter '*.js' -File -ErrorAction SilentlyContinue
        Get-ChildItem -Path $PSScriptRoot -Filter '*.css' -File -ErrorAction SilentlyContinue
    )

    $latestIndex = $assets |
        Where-Object { $_.Name -like 'index.*bundle.js' } |
        Sort-Object -Property LastWriteTime -Descending |
        Select-Object -First 1

    foreach ($asset in $assets) {
        $registered = [UniversalDashboard.Services.AssetService]::Instance.RegisterAsset($asset.FullName)
        if ($latestIndex -and $asset.FullName -eq $latestIndex.FullName) {
            $Script:AssetId = $registered
        }
    }
}
catch {
    Write-Verbose "UniversalDashboard asset service not available: $_"
}

$Public = @(Get-ChildItem -Path "$PSScriptRoot\public\*.ps1" -ErrorAction SilentlyContinue)
$Private = @(Get-ChildItem -Path "$PSScriptRoot\private\*.ps1" -ErrorAction SilentlyContinue)

foreach ($import in @($Public + $Private)) {
    try {
        . $import.FullName
    }
    catch {
        Write-Error -Message "Failed to import function $($import.FullName): $_"
    }
}
