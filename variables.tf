variable "location" {
  description = "Primary Azure region"
  type        = string
  default     = "eastus"
}

variable "image_definition_name" {
  description = "Name of the image definition"
  type        = string
  default     = "golden-image"
}

variable "image_version" {
  description = "Version of the image"
  type        = string
  default     = "1.0.0"
}

variable "publisher" {
  description = "Image publisher"
  type        = string
  default     = "MicrosoftWindowsDesktop"
}

variable "offer" {
  description = "Image offer"
  type        = string
  default     = "windows-11"
}

variable "sku" {
  description = "Image SKU"
  type        = string
  default     = "win11-22h2-pro"
}
