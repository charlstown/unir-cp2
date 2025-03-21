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

# Crear un grupo de recursos en West Europe
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Llamar al módulo de la máquina virtual
module "virtual_machine" {
  source             = "./modules/vm"
  resource_group     = azurerm_resource_group.rg.name
  location           = azurerm_resource_group.rg.location
  vm_name            = "${var.vm_name}-${var.environment}"
  vm_size            = var.vm_size
  admin_username     = var.vm_username
  ssh_public_key     = file("${var.ssh_public_key}")
  vnet_name          = "${var.vnet_name}-${var.environment}"
  subnet_name        = "${var.subnet_name}-${var.environment}"
  subnet_cidr        = var.subnet_cidr
  image_os           = var.image_os
  image_offer        = var.image_offer
  tags               = var.tags
}

# Llamar al módulo del Registro de Contenedores (ACR)
module "container_registry" {
  source         = "./modules/acr"
  resource_group = azurerm_resource_group.rg.name
  location       = azurerm_resource_group.rg.location
  acr_name       = "${var.acr_name}${var.environment}"
  tags           = var.tags
}

# Llamar al módulo del AKS
module "aks" {
  source          = "./modules/aks"
  aks_name        = "${var.aks_name}-${var.environment}"
  resource_group  = azurerm_resource_group.rg.name
  location        = azurerm_resource_group.rg.location
  dns_prefix      = var.dns_prefix
  node_count      = var.node_count
  vm_size         = var.aks_vm_size
  acr_id          = module.container_registry.acr_id
  tags            = var.tags
}

# Generar el archivo hosts.yml
resource "local_file" "ansible_inventory" {
  filename = "../ansible/hosts.yml"
  content  = templatefile("../ansible/hosts.tmpl", {
    vm_name             = var.vm_name
    vm_public_ip        = module.virtual_machine.vm_public_ip
    vm_username         = var.vm_username
    ssh_private_key     = "~/.ssh/az_unir_rsa"
    python_interpreter  = var.python_interpreter
    acr_name            = "${var.acr_name}${var.environment}"
    acr_login_server    = "${var.acr_name}${var.environment}.azurecr.io"
    acr_username        = module.container_registry.acr_username
    acr_password        = module.container_registry.acr_password
    aks_name            = var.aks_name
    aks_resource_group  = var.resource_group_name
  })
}
