# Builds the JS bundle and stages a deployable module in .\output\PowerShellUniversal.Component.Chameleon
[CmdletBinding()]
param(
    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot 'output\PowerShellUniversal.Component.Chameleon')
)

$ErrorActionPreference = 'Stop'
$ModulePath = Join-Path $PSScriptRoot 'PowerShellUniversal.Component.Chameleon'
# Never allow staging to delete the repository or the module source.
$OutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputPath)
$OutputPath = [System.IO.Path]::GetFullPath($OutputPath).TrimEnd('\', '/')
foreach ($SourcePath in @($PSScriptRoot, $ModulePath)) {
    $SourcePath = [System.IO.Path]::GetFullPath($SourcePath)
    if ($SourcePath -eq $OutputPath -or $SourcePath.StartsWith($OutputPath.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw 'OutputPath must not be the repository, module source, or a parent of either.'
    }
}
if ($OutputPath.StartsWith($ModulePath + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'OutputPath must not be inside the module source.'
}

Push-Location $PSScriptRoot
try {
    Write-Host 'Installing npm dependencies...' -ForegroundColor Cyan
    npm install
    if ($LASTEXITCODE -ne 0) { throw 'npm install failed' }

    Write-Host 'Building component bundle...' -ForegroundColor Cyan
    npm run build
    if ($LASTEXITCODE -ne 0) { throw 'npm run build failed' }

    if (Test-Path -LiteralPath $OutputPath) {
        Remove-Item -LiteralPath $OutputPath -Recurse -Force
    }
    $null = New-Item -Path $OutputPath -ItemType Directory -Force

    # Stage only runtime assets; never copy the repository or development folders.
    Copy-Item -Path (Join-Path $PSScriptRoot 'dist\*') -Destination $OutputPath
    Copy-Item -Path (Join-Path $ModulePath 'PowerShellUniversal.Component.Chameleon.ps*1') -Destination $OutputPath
    foreach ($Folder in 'public', 'private', 'dashboards', '.universal') {
        Copy-Item -Path (Join-Path $ModulePath $Folder) -Destination $OutputPath -Recurse -Force
    }

    $null = Test-ModuleManifest -Path (Join-Path $OutputPath 'PowerShellUniversal.Component.Chameleon.psd1')
    Write-Host "Build complete: $OutputPath" -ForegroundColor Green
}
finally {
    Pop-Location
}
