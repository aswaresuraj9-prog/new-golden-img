
locals { tags = { workload = "image-builder", owner = "terraform" } }

resource "random_string" "suffix" {
  length = 5
  upper = false
  special = false
}

resource "azurerm_resource_group" "rg" {
  name = var.rg_name
  location = var.location
  tags = local.tags
}

resource "azurerm_virtual_network" "vnet" {
  name = "vnet-aib-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  address_space = ["10.20.0.0/16"]
}

resource "azurerm_subnet" "aib" {
  name = "snet-aib"
  resource_group_name = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes = ["10.20.1.0/24"]
}

resource "azurerm_public_ip" "nat" {
  name = "pip-nat-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  allocation_method = "Static"
  sku = "Standard"
}

resource "azurerm_nat_gateway" "ngw" {
  name = "ngw-aib-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  sku_name = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "assoc" {
  nat_gateway_id = azurerm_nat_gateway.ngw.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "snet_assoc" {
  subnet_id = azurerm_subnet.aib.id
  nat_gateway_id = azurerm_nat_gateway.ngw.id
}

resource "azurerm_user_assigned_identity" "aib_uai" {
  name = "uai-aib-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
}

resource "azurerm_shared_image_gallery" "sig" {
  name = var.gallery_name
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location
  description = "Shared Image Gallery for golden images"
}


resource "azurerm_shared_image" "image_def" {
  name                = var.image_definition_name
  gallery_name        = azurerm_shared_image_gallery.sig.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  os_type            = "Windows"
  hyper_v_generation = "V2"
  specialized        = false
  architecture       = "x64"

  identifier {
    publisher = "Contoso"
    offer     = "Golden"
    sku       = "Win11-AVD"
  }

  tags = local.tags
}



resource "azapi_resource" "image_template" {
  type = "Microsoft.VirtualMachineImages/imageTemplates@2023-07-01"
  name = "aib-tmpl-${random_string.suffix.result}"
  location = azurerm_resource_group.rg.location
  parent_id = azurerm_resource_group.rg.id
 identity {
  type         = "UserAssigned"
  identity_ids = [azurerm_user_assigned_identity.aib_uai.id]
}




  body = jsonencode({
    properties = {
      source = {
        type = "PlatformImage"
        publisher = var.source_publisher
        offer = var.source_offer
        sku = var.source_sku
        version = "latest"
      },
      customize = [
        {
          type = "PowerShell"
          name = "InstallApps"
          inline = [
            "$ProgressPreference = 'SilentlyContinue'",
            "winget install --id 7zip.7zip --silent --accept-package-agreements --accept-source-agreements --disable-interactivity",
            "winget install --id Google.Chrome --silent --accept-package-agreements --accept-source-agreements --disable-interactivity"
          ]
        },
        {
          type = "PowerShell"
          name = "PostConfig"
          inline = [
            "Set-ItemProperty -Path 'HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Terminal Server' -Name 'fDenyTSConnections' -Value 0",
            "Enable-NetFirewallRule -DisplayGroup 'Remote Desktop'"
          ]
        }
      ],
    distribute = [
  {
    type            = "SharedImage"
    galleryImageId  = azurerm_shared_image.image_def.id
    runOutputName   = "aib-sig-output"
    excludeFromLatest = false

    # Build region objects from your var.replication_regions
    targetRegions = [
      for r in var.replication_regions : {
        name               = r
        storageAccountType = "Standard_LRS"
        # replicaCount     = 1   # optional
      }
    ]
  }
]

    }
  })
}


# Run the image template (build + distribute)
resource "azapi_resource_action" "run_image" {
  type        = "Microsoft.VirtualMachineImages/imageTemplates@2023-07-01"
  resource_id = azapi_resource.image_template.id
  action      = "run"
  method      = "POST"
  # Wait for completion
  response_export_values = ["*"]
}

# After successful run, clean up NAT + Public IP
resource "null_resource" "cleanup_after_build" {
  depends_on = [azapi_resource_action.run_image]
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-ExecutionPolicy", "Bypass", "-File"]
    command     = "${path.module}/scripts/03-cleanup.ps1"
  }
  provisioner "local-exec" {
    when        = destroy
    command     = "echo 'noop'"
  }
}


resource "github_actions_secret" "azure_secrets" {
  for_each = {
    AZURE_CLIENT_ID        = var.azure_client_id
    AZURE_TENANT_ID        = var.azure_tenant_id
    AZURE_SUBSCRIPTION_ID  = var.azure_subscription_id
    AZURE_CLIENT_SECRET    = var.azure_client_secret
  }

  repository      = var.repo_name
  secret_name     = each.key
  plaintext_value = each.value
}

# Optionally remove those resources from Terraform state to avoid drift
resource "null_resource" "cleanup_state" {
  depends_on = [null_resource.cleanup_after_build]
  provisioner "local-exec" {
    interpreter = ["PowerShell", "-ExecutionPolicy", "Bypass", "-File"]
    command     = "${path.module}/scripts/04-fix-state.ps1"
  }
}
