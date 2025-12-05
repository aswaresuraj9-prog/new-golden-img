# 01-install-apps.ps1
# Installs 7-Zip and Google Chrome via winget with retries

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

function Install-WingetPackage {
    param([Parameter(Mandatory)][string]$Id)
    for ($i=0; $i -lt 5; $i++) {
        try {
            winget install --id $Id --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
            Write-Host "Installed $Id"
            return
        } catch {
            Write-Warning "Failed to install $Id. Attempt $($i+1)/5. Retrying in 10s..."
            Start-Sleep -Seconds 10
        }
    }
    throw "Failed to install $Id after 5 attempts."
}

Install-WingetPackage -Id "7zip.7zip"
Install-WingetPackage -Id "Google.Chrome"