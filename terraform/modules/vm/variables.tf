# General Variables
variable "resource_group" { type = string }
variable "location" { type = string }
variable "vm_name" { type = string }
variable "vm_size" { type = string }
variable "admin_username" { type = string }
variable "ssh_public_key" { type = string }

# Networking Variables
variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the Subnet"
  type        = string
}

variable "subnet_cidr" {
  description = "Subnet CIDR block"
  type        = string
}

# OS Image Variable
variable "image_os" {
  description = "OS Image SKU for the VM"
  type        = string
}

# Image offer Variable
variable "image_offer" {
  description = "Image offer for the VM"
  type        = string
}

variable "tags" {
  description = "Tags to be applied to resources"
  type        = map(string)
}
