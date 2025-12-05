# load-azure-env.ps1
param([string]$EnvFile = ".terraform.azure.env")

if (-not (Test-Path $EnvFile)) {
  throw "Env file '$EnvFile' not found. Create it with ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID, ARM_SUBSCRIPTION_ID."
}

Get-Content $EnvFile | ForEach-Object {
  if ($_ -match '^\s*#') { return }
  if ($_ -match '^\s*$') { return }
  if ($_ -match '^\s*([^=\s]+)\s*=\s*(.+)\s*$') {
    $name = $matches[1]
    $value = $matches[2]
    [Environment]::SetEnvironmentVariable($name, $value, "Process")
    Write-Host "Loaded $name"
  }
}
Write-Host "Environment variables loaded."