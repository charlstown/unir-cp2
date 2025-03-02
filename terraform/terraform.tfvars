# Generic
resource_group_name = "rg-dev-weu-cp2"
location            = "West Europe"

# ACR
acr_name            = "acrdevweucp2"

# virtual machine
vm_name             = "vm-dev-weu-cp2-docs"
vm_username         = "charlstown"
vm_size             = "Standard_B1ls"

# Networking
vnet_name           = "vnet-dev-weu-cp2"
subnet_name         = "subnet-dev-weu-cp2"
subnet_cidr         = "10.0.1.0/24"

# OS image
image_os            = "18.04-LTS"