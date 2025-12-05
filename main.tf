provider "azurerm" {
  features {}
}

resource "random_string" "suffix" {
  length  = 5
  upper   = false
  special = false
}

resource "azurerm_resource_group" "rg" {
  name     = "new-image-gold-rg"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-aib-${random_string.suffix.result}"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet" {
  name                 = "snet-aib"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "pip-aib-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_nat_gateway" "nat" {
  name                = "nat-aib-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku_name            = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "nat_assoc" {
  nat_gateway_id       = azurerm_nat_gateway.nat.id
  public_ip_address_id = azurerm_public_ip.pip.id
}

resource "azurerm_subnet_nat_gateway_association" "subnet_nat_assoc" {
  subnet_id      = azurerm_subnet.subnet.id
  nat_gateway_id = azurerm_nat_gateway.nat.id
}

resource "azurerm_user_assigned_identity" "uai" {
  name                = "uai-aib-${random_string.suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_shared_image_gallery" "sig" {
  name                = "sig_golden"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  description         = "Shared Image Gallery for golden images"
}

resource "azurerm_shared_image" "image_def" {
  name                = var.image_definition_name
  gallery_name        = azurerm_shared_image_gallery.sig.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  os_type             = "Windows"
  hyper_v_generation  = "V2"
  specialized         = false
  architecture        = "x64"

  identifier {
    publisher = var.publisher
    offer     = var.offer
    sku       = var.sku
  }
}

resource "azapi_resource" "image_template" {
  type      = "Microsoft.VirtualMachineImages/imageTemplates@2023-07-01"
  name      = "aib-template-${random_string.suffix.result}"
  location  = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.uai.id]
  }

  body = jsonencode({
    properties = {
      source = {
        type      = "PlatformImage"
        publisher = var.publisher
        offer     = var.offer
        sku       = var.sku
        version   = "latest"
      }
      customize = [
        {
          type   = "PowerShell"
          name   = "InstallApps"
          inline = [
            "$ProgressPreference = 'SilentlyContinue'",
            "winget install --id 7zip.7zip --silent --accept-package-agreements --accept-source-agreements",
            "winget install --id Google.Chrome --silent --accept-package-agreements --accept-source-agreements"
          ]
        }
      ]
      distribute = [
        {
          type              = "SharedImage"
          galleryImageId    = azurerm_shared_image.image_def.id
          runOutputName     = "aib-sig-output"
          excludeFromLatest = false
          targetRegions     = [
            {
              name               = "eastus"
              storageAccountType = "Standard_LRS"
            },
            {
              name               = "centralindia"
              storageAccountType = "Standard_LRS"
            }
          ]
        }
      ]
    }
  })
}

resource "azapi_resource_action" "run_image" {
  type        = "Microsoft.VirtualMachineImages/imageTemplates@2023-07-01"
  resource_id = azapi_resource.image_template.id
  action      = "run"
  method      = "POST"
  response_export_values = ["*"]
}

resource "azurerm_shared_image_version" "image_version" {
  name                = var.image_version
  gallery_name        = azurerm_shared_image_gallery.sig.name
  resource_group_name = azurerm_resource_group.rg.name
  image_name          = azurerm_shared_image.image_def.name
  location            = azurerm_resource_group.rg.location
  managed_image_id    = azapi_resource_action.run_image.response_export_values[0]

  target_region {
    name                   = "eastus"
    regional_replica_count = 1
  }

  target_region {
    name                   = "centralindia"
    regional_replica_count = 1
  }
}
