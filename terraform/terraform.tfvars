# Generic
resource_group_name = "rg-weu-cp2"
location            = "West Europe"
environment         = "dev"

# ACR
acr_name            = "acrweucp2"

# virtual machine
vm_name             = "vm-weu-cp2-docs"
vm_username         = "charlstown"
vm_size             = "Standard_B1ms"
# "Standard_B1ls" sin suficiente memoria
ssh_public_key      = "~/.ssh/az_unir_rsa.pub"
python_interpreter  = "/usr/bin/python3"

# Networking
vnet_name           = "vnet-weu-cp2"
subnet_name         = "subnet-weu-cp2"
subnet_cidr         = "10.0.1.0/28"

# Image
image_os            = "22_04-lts-gen2"
image_offer         = "0001-com-ubuntu-server-jammy"
# check offers here: https://documentation.ubuntu.com/azure/en/latest/azure-how-to/instances/find-ubuntu-images/

# AKS
aks_name            = "aks-weu-cp2"
dns_prefix          = "aksweucp2"
node_count          = 1
aks_vm_size         = "Standard_B2s"

# Tags
tags = {
  environment = "casopractico2"
}