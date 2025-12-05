# 03-cleanup.ps1
param([string]$ResourceGroup = "new-image-gold-rg")

$ErrorActionPreference = "Continue"
Write-Host "Cleanup: removing NAT associations, NAT gateways, and Public IPs in RG '$ResourceGroup'..." -ForegroundColor Cyan

# Remove NAT association from subnets
$vnets = az network vnet list -g $ResourceGroup | ConvertFrom-Json
foreach ($vnet in $vnets) {
  $subnets = az network vnet subnet list -g $ResourceGroup --vnet-name $vnet.name | ConvertFrom-Json
  foreach ($s in $subnets) {
    if ($s.natGateway) {
      Write-Host "Detaching NAT from subnet $($s.name) in vnet $($vnet.name)..."
      az network vnet subnet update -g $ResourceGroup --vnet-name $vnet.name -n $s.name --remove natGateway.id 1>$null
    }
  }
}

# Delete NAT gateways
$natgws = az network nat gateway list -g $ResourceGroup | ConvertFrom-Json
foreach ($ng in $natgws) {
  Write-Host "Deleting NAT gateway $($ng.name)..."
  az network nat gateway delete -g $ResourceGroup -n $ng.name 1>$null
}

# Delete Public IPs
$pips = az network public-ip list -g $ResourceGroup | ConvertFrom-Json
foreach ($pip in $pips) {
  Write-Host "Deleting Public IP $($pip.name)..."
  az network public-ip delete -g $ResourceGroup -n $pip.name 1>$null
}

Write-Host "Cleanup complete." -ForegroundColor Green
