variable "resource_group_name" {
  description = "The name of the resource group"
  type        = string
  default     = "rg-dev-weu-cp2"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "West Europe"
}

variable "acr_name" {
  description = "ACR name"
  type        = string
}

variable "vm_name" {
  description = "Virtual Machine name"
  type        = string
  default     = "myUbuntuVM"
}

variable "vm_username" {
  description = "Virtual Machine username"
  type        = string
  default     = "charlstown"
}

variable "vm_size" {
  description = "Azure VM size"
  type        = string
  default     = "Standard_B1ls"  # Cheapest VM
}

# Networking
variable "vnet_name" {
  description = "Virtual Network Name"
  type        = string
  default     = "vnet-dev-weu-cp2"
}

variable "subnet_name" {
  description = "Subnet Name"
  type        = string
  default     = "subnet-dev-weu-cp2"
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
  default     = "20.04-LTS"
}