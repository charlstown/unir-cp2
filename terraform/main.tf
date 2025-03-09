terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

# Configuración del proveedor de Azure
provider "azurerm" {
  subscription_id = "fb24fc1f-67e2-4871-8be2-c10a36e74c93" # ID de suscripción de Azure para Estudiantes
  features {}
}

# 🔹 Define Environment Suffix in One Place
locals {
  env_suffix = "-${var.environment}"
}

# 🔹 Crear un grupo de recursos en West Europe
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}-${var.environment}"
  location = var.location
}

# 🔹 Llamar al módulo de la máquina virtual
module "virtual_machine" {
  source             = "./modules/vm"
  resource_group     = azurerm_resource_group.rg.name
  location           = azurerm_resource_group.rg.location
  vm_name            = "${var.vm_name}-${var.environment}"
  vm_size            = var.vm_size
  admin_username     = var.vm_username
  ssh_public_key     = file("~/.ssh/az_unir_rsa.pub")
  vnet_name          = "${var.vnet_name}-${var.environment}"
  subnet_name        = "${var.subnet_name}-${var.environment}"
  subnet_cidr        = var.subnet_cidr
  image_os           = var.image_os
  image_offer           = var.image_offer
}

# 🔹 Llamar al módulo del Registro de Contenedores (ACR)
module "container_registry" {
  source         = "./modules/acr"
  resource_group = azurerm_resource_group.rg.name
  location       = azurerm_resource_group.rg.location
  acr_name       = "${var.acr_name}${var.environment}"
}
