# 04-fix-state.ps1
# Removes deleted temp resources from Terraform state to avoid drift
$ErrorActionPreference = "Continue"

$addresses = @(
  "azurerm_nat_gateway.ngw",
  "azurerm_public_ip.nat",
  "azurerm_nat_gateway_public_ip_association.assoc",
  "azurerm_subnet_nat_gateway_association.snet_assoc"
)

foreach ($addr in $addresses) {
  Write-Host "Removing $addr from Terraform state (if present)..."
  terraform state rm $addr 2>$null
}
Write-Host "State cleanup complete."
