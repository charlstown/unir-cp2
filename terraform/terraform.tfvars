# Generic
resource_group_name = "rg-weu-cp2"
location            = "West Europe"

# ACR
acr_name            = "acrweucp2"

# virtual machine
vm_name             = "vm-weu-cp2-docs"
vm_username         = "charlstown"
vm_size             = "Standard_B1ls"

# Networking
vnet_name           = "vnet-weu-cp2"
subnet_name         = "subnet-weu-cp2"
subnet_cidr         = "10.0.1.0/24"

# OS image
image_os            = "18.04-LTS"