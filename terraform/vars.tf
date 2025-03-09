variable "environment" {
  description = "Deployment environment: dev, pre, pro"
  type        = string
  default     = "dev"
}

variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "rg-weu-cp2"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}

variable "acr_name" {
  description = "ACR name"
  type        = string
  default     = "acrdevweucp2"
}

variable "vm_name" {
  description = "Virtual Machine name"
  type        = string
  default     = "vm-weu-cp2-docs"
}

variable "vm_username" {
  description = "Virtual Machine username"
  type        = string
  default     = "charlstown"
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_B1ls"
}

# Networking
variable "vnet_name" {
  description = "Virtual Network Name"
  type        = string
  default     = "vnet-weu-cp2"
}

variable "subnet_name" {
  description = "Subnet Name"
  type        = string
  default     = "subnet-weu-cp2"
}

variable "subnet_cidr" {
  description = "Subnet CIDR Block"
  type        = string
  default     = "10.0.1.0/24"
}

# OS Image
variable "image_os" {
  description = "OS Image SKU"
  type        = string
  default     = "18.04-LTS"
}

# Image offer
variable "image_offer" {
  description = "Image offer"
  type        = string
  default     = "UbuntuServer"
}
