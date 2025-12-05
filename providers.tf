terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.113"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.13"
    }
  }
}

provider "azurerm" {
  features {}
  use_cli         = true
  subscription_id = "19ad1a00-018f-4a1b-9d74-5f9293461a79"
}

provider "azapi" {
  use_cli         = true
  subscription_id = "19ad1a00-018f-4a1b-9d74-5f9293461a79"
}

