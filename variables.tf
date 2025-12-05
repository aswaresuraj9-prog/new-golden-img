variable "rg_name" {
  description = "The name of the resource group"
  default     = "new-image-gold-rg"
}

variable "location" {
  description = "Azure region for resources"
  default     = "eastus"
}

variable "replication_regions" {
  description = "List of regions for image replication"
  default     = ["eastus", "centralindia"]
}

variable "gallery_name" {
  description = "Name of the Shared Image Gallery"
  default     = "sig_golden"
}

variable "image_definition_name" {
  description = "Name of the image definition"
  default     = "win11-avd-golden"
}

variable "image_version" {
  description = "The version of the image"
  default     = "1.0.0"
}

variable "source_publisher" {
  description = "The publisher of the base image"
  default     = "MicrosoftWindowsDesktop"
}

variable "source_offer" {
  description = "The offer of the base image"
  default     = "Windows-11"
}

variable "source_sku" {
  description = "The SKU of the base image"
  default     = "win11-24h2-avd"
}




