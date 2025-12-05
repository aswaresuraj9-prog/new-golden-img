
variable "rg_name" { default = "new-image-gold-rg" }
variable "location" { default = "eastus" }
variable "replication_regions" { default = ["eastus", "centralindia"] }
variable "gallery_name" { default = "sig_golden" }
variable "image_definition_name" { default = "win11-avd-golden" }
variable "image_version" { default = "1.0.0" }

variable "source_publisher" { default = "MicrosoftWindowsDesktop" }
variable "source_offer" { default = "Windows-11" }
variable "source_sku" { default = "win11-24h2-avd" }
