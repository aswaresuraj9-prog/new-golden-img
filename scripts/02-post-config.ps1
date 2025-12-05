# 02-post-config.ps1
# Basic AVD tuning, enable RDP, install FSLogix, and apply Windows updates

$ErrorActionPreference = "Stop"
$ProgressPreference = 'SilentlyContinue'

Write-Host "Enabling RDP and firewall rules..."
Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server' -Name 'fDenyTSConnections' -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

$fsTemp = "C:\Temp\fslogix"
New-Item -ItemType Directory -Force -Path $fsTemp | Out-Null

Write-Host "Downloading FSLogix..."
Invoke-WebRequest -Uri "https://aka.ms/fslogix_download" -OutFile "$fsTemp\fslogix.zip"

Expand-Archive -Path "$fsTemp\fslogix.zip" -DestinationPath $fsTemp -Force

$msiPath = Get-ChildItem -Path $fsTemp -Recurse -Filter "FSLogixAppsSetup.msi" | Select-Object -First 1 -ExpandProperty FullName
if (-not $msiPath) { throw "FSLogix MSI not found after extraction." }
Start-Process msiexec.exe -ArgumentList "/i `"$msiPath`" /qn /norestart" -Wait

try {
    Write-Host "Installing PSWindowsUpdate module and running updates..."
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force | Out-Null
    Install-Module PSWindowsUpdate -Force -Confirm:$false | Out-Null
    Import-Module PSWindowsUpdate
    Get-WindowsUpdate -AcceptAll -Install -IgnoreReboot | Out-Null
} catch {
    Write-Warning "Windows Update step failed or repository blocked. Continuing. Details: $_"
}

Write-Host "Post-config complete."