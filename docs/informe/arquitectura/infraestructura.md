# :simple-terraform: Infraestructura

A continuación se describen los diferentes componentes de la infraestructura desplegados con terraform y la justificación de sus configuraciones.

## Estructura de ficheros Terraform

Para la implementación de la infraestructura, se ha seguido una organización modular en Terraform, siguiendo las mejores prácticas recomendadas en la comunidad [(Stivenson, 2023)](../referencias.md). A continuación, se describe la estructura de los archivos y su propósito dentro del proyecto.

```plaintext
terraform/
├── main.tf           # Archivo principal que llama a los módulos y recursos
├── modules/          # Carpeta que contiene los módulos de infraestructura
│   ├── acr/          # Módulo para desplegar Azure Container Registry (ACR)
│   ├── aks/          # Módulo para desplegar Azure Kubernetes Service (AKS)
│   └── vm/           # Módulo para desplegar la máquina virtual en Azure
├── outputs.tf        # Define las salidas (outputs) de Terraform
├── terraform.tfvars  # Define valores específicos para esta implementación
└── vars.tf           # Define las variables requeridas para el despliegue
```

### Fichero principal `main.tf`

El archivo main.tf define la infraestructura base del proyecto y se estructura en tres secciones principales:

- **Configuración base:** define el proveedor azurerm, el grupo de recursos y variables locales para el entorno.
- **Llamada a los módulos:** incluyendo la máquina virtual (VM), el registro de contenedores (ACR) y el clúster de Kubernetes (AKS).
- **Generación dinámica del inventario de Ansible:** crea automáticamente un archivo hosts.yml con la información de conexión necesaria para la configuración mediante Ansible.

#### Configuración base

```hcl title="main.tf"
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
  subscription_id = "fb24fc1f-67e2-4871-8be2-c10a36e74c93"
  features {}
}

# Define la variable de entorno elegida para el despliegue
locals {
  env_suffix = "-${var.environment}"
}

# Crear un grupo de recursos en West Europe
resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}
```

#### Llamada a módulos

Contiene la llamada a los diferentes módulos de infraestructura, incluyendo la máquina virtual (VM), el registro de contenedores (ACR) y el clúster de Kubernetes (AKS).

A continuación, se muestra un ejemplo de la estructura de un módulo en main.tf, en este caso, la definición del AKS:

```hcl title="main.tf"
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
```


#### Generación del inventario

La generación del inventario de Ansible se realiza dinámicamente con Terraform para automatizar la configuración de la infraestructura. Se emplea el recurso `local_file` para crear el archivo `hosts.yml` basado en una plantilla que incluye información clave de los recursos desplegados:

- **Máquina virtual**: Dirección IP pública, usuario y clave SSH.
- **Azure Container Registry (ACR)**: Nombre, servidor de login, credenciales de acceso.
- **Clúster AKS**: Nombre y grupo de recursos asociado.

```hcl title="main.tf"
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
```

Esta instrucción de terraform apunta al fichero `hosts.tmpl` de la carpeta de ansible y que usa como plantilla para generar el fichero de inventario `hosts.yml`.

```yaml title="hosts.tmpl"
all:
  children:
    azure_vm:
      hosts:
        ${vm_name}:
          ansible_host: ${vm_public_ip}
          ansible_user: ${vm_username}
          ansible_ssh_private_key_file: ${ssh_private_key}
          ansible_python_interpreter: ${python_interpreter}

    azure_acr:
      hosts:
        ${acr_name}:
          acr_login_server: ${acr_login_server}

    azure_aks:
      hosts:
        ${aks_name}:
          aks_resource_group: ${aks_resource_group}
          ansible_connection: local
          ansible_python_interpreter: /usr/bin/python3
```

Esto permite que Ansible trabaje con información actualizada sin intervención manual, garantizando coherencia y simplificando la configuración.

### Fichero `terraform.tfvars`

El fichero define las variables utilizadas en el despliegue de la infraestructura, priorizando configuraciones de bajo coste para optimizar el uso de recursos en el ejercicio. 

Se establece un entorno de desarrollo (`dev`), una máquina virtual con especificaciones mínimas y un clúster AKS con un solo nodo. Además, se configura un ACR y una red con una subred pequeña para evitar sobreasignación de recursos innecesaria.

```hcl title="terraform.tfvars"
# Generic
resource_group_name = "rg-weu-cp2"
location            = "West Europe"
environment         = "dev"

# ACR
acr_name            = "acrweucp2"

# virtual machine
vm_name             = "vm-weu-cp2-docs"
vm_username         = "charlstown"
vm_size             = "Standard_B1ms"   # "Standard_B1ls"
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
```

## Módulos

### Container registry

La infraestructura de **Azure Container Service(ACR)** se ha definido utilizando **Terraform**, organizando los recursos en módulos separados para mejorar la modularidad y reutilización del código. A continuación, se presentan los archivos principales que definen el despliegue:

```plaintext
terraform/
│── terraform.tfvars        # Variables globales del despliegue
│── main.tf                 # Llamada a módulos y recursos principales
│── modules/
│   ├── acr/                # Módulo del ACR
│   │   ├── main.tf         # Definición del ACR
│   │   ├── outputs.tf      # Variables de salida
│   │   └── variables.tf    # Definición de variables del módulo
```

#### Fichero `main.tf`

El fichero `main.tf` del módulo del ACR recoge únicamente el recurso `azurerm_container_registry`.

```hcl title="main.tf"
# Crear Azure Container Registry (ACR)
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = var.resource_group
  location            = var.location
  sku                 = "Basic"  # Opción más barata
  admin_enabled       = true
  tags                = var.tags
}
```

| **Parámetro**     | **Descripción** |
|----------------------------|--------------------------------|
| **`var.acr_name`**         | Define el nombre del registro de contenedores. Se usa una variable para permitir reutilización y facilitar la personalización sin modificar el código. |
| **`var.resource_group`**   | Especifica el grupo de recursos donde se desplegará el ACR. |
| **`var.location`**         | Indica la región de Azure en la que se despliega el registro. |
| **`sku = "Basic"`**        | Se elige el nivel **Basic**, ya que es la opción más económica y suficiente para los requisitos del ejercicio. Alternativamente, se podría usar `Standard` o `Premium` si se requiriera mayor escalabilidad o funcionalidades adicionales. |
| **`admin_enabled = true`** | Habilita el acceso mediante credenciales de administrador. Se activa para simplificar la autenticación en el entorno de pruebas, aunque en entornos de producción sería recomendable deshabilitarlo y usar autenticación con identidades de Azure AD. |
| **`tags = var.tags`**      | Permite agregar metadatos al recurso para organización y clasificación dentro de Azure. |


### Máquina virtual

La infraestructura de la máquina virtual se ha definido utilizando **Terraform**, organizando los recursos en módulos separados para mejorar la modularidad y reutilización del código. A continuación, se presentan los archivos principales que definen el despliegue:

```bash
terraform/
│── terraform.tfvars        # Variables globales del despliegue
│── main.tf                 # Llamada a módulos y recursos principales
│── modules/
│   ├── vm/                 # Módulo de la máquina virtual
│   │   ├── main.tf         # Definición de la VM
│   │   ├── network.tf      # Configuración de la red
│   │   ├── security.tf     # Reglas de seguridad (NSG)
│   │   ├── outputs.tf      # Variables de salida (IPs, VM ID)
│   │   └── variables.tf    # Definición de variables del módulo
```

#### Fichero `main.tf`

El fichero `main.tf` del módulo de la máquina virtual recoge los siguientes recursos:

- *IP Pública* → Asigna una dirección IP fija a la VM para acceso remoto.  
- *Interfaz de Red (NIC)* → Proporciona conectividad a la máquina virtual en la red definida.  
- *Máquina Virtual (VM)* → Instancia de un sistema operativo en Azure con configuración personalizada.  


##### IP Pública

```hcl title="main.tf"
resource "azurerm_public_ip" "vm_public_ip" {
  name                = "${var.vm_name}-public-ip"
  resource_group_name = var.resource_group
  location            = var.location
  allocation_method   = "Static"
  tags                = var.tags
}
```

| **Parámetro**                   | **Descripción** |
|----------------------------------|--------------------------------|
| **`var.vm_name`**                | Se usa para nombrar la IP pública de la VM de manera única dentro del recurso. |
| **`var.resource_group`**         | Grupo de recursos en el que se despliega la IP pública. |
| **`var.location`**               | Región de Azure donde se asignará la IP. |
| **`allocation_method = "Static"`** | Se usa IP **estática** para mantener una dirección fija y evitar cambios en reinicios. |
| **`var.tags`**                   | Se añaden etiquetas para organización y clasificación dentro de Azure. |

##### Interfaz de Red (NIC)

```hcl title="main.tf"
resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  resource_group_name = var.resource_group
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet.id
    public_ip_address_id          = azurerm_public_ip.vm_public_ip.id
    private_ip_address_allocation = "Dynamic"
  }
  tags = var.tags
}
```

| **Parámetro**                   | **Descripción** |
|----------------------------------|--------------------------------|
| **`var.vm_name`**                | Nombre de la interfaz de red, vinculado a la VM. |
| **`var.resource_group`**         | Grupo de recursos donde se crea la NIC. |
| **`var.location`**               | Región donde se despliega la interfaz. |
| **`var.subnet_id`**              | Identificador de la subred a la que se conecta la NIC. |
| **`var.public_ip_address_id`**   | Asigna la **IP pública estática** previamente definida. |
| **`private_ip_address_allocation = "Dynamic"`** | Permite que Azure asigne automáticamente una IP privada a la VM. |
| **`var.tags`**                   | Se incluyen etiquetas para organización. |


##### Máquina Virtual Linux

```hcl title="main.tf"
resource "azurerm_linux_virtual_machine" "vm" {
  name                  = var.vm_name
  resource_group_name   = var.resource_group
  location              = var.location
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = var.image_offer
    sku       = var.image_os
    version   = "latest"
  }
  tags = var.tags
}
```
 
| **Parámetro**                   | **Descripción** |
|----------------------------------|--------------------------------|
| **`var.vm_name`**                | Nombre de la máquina virtual. |
| **`var.resource_group`**         | Grupo de recursos en el que se despliega la VM. |
| **`var.location`**               | Región donde se despliega la máquina. |
| **`var.vm_size`**                | Tipo de máquina virtual seleccionada para optimizar coste y rendimiento. |
| **`var.admin_username`**         | Usuario administrador de la VM. |
| **`var.ssh_public_key`**         | Clave pública SSH para autenticación sin contraseña. |
| **`var.network_interface_ids`**  | Conecta la VM a la interfaz de red creada. |
| **`caching = "ReadWrite"`**      | Optimización del rendimiento del disco del sistema. |
| **`storage_account_type = "Standard_LRS"`** | Tipo de almacenamiento del disco OS, seleccionado por costo y disponibilidad. |
| **`var.image_offer`**            | Imagen de sistema operativo en el Azure Marketplace. |
| **`var.image_os`**               | Versión específica del sistema operativo (`Ubuntu 22.04 LTS`). |
| **`var.tags`**                   | Etiquetas para gestión y organización dentro de Azure. |


#### Fichero `network.tf`

El fichero `network.tf` del módulo de la máquina virtual recoge los siguientes recursos:  

- *Red Virtual (VNet)* → Define el espacio de direcciones y la conectividad general.  
- *Subred* → Segmenta la red dentro de la VNet, optimizando la asignación de direcciones IP.

##### Red Virtual (VNet)

```hcl title="network.tf"
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.resource_group
  location            = var.location
  address_space       = ["10.0.0.0/16"]
  tags                = var.tags
}
```
 
| **Parámetro**                   | **Descripción** |
|----------------------------------|--------------------------------|
| **`var.vnet_name`**              | Nombre de la red virtual, definido como variable para flexibilidad. |
| **`var.resource_group`**         | Grupo de recursos donde se despliega la VNet. |
| **`var.location`**               | Región de Azure donde se crea la red. |
| **`address_space = ["10.0.0.0/16"]`** | Espacio de direcciones IP asignado a la red virtual, lo que permite futuras segmentaciones. |
| **`var.tags`**                   | Etiquetas opcionales para organización y gestión en Azure. |


##### Subred

```hcl title="network.tf"
resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_cidr]
}
```
 
| **Parámetro**                   | **Descripción** |
|----------------------------------|--------------------------------|
| **`var.subnet_name`**            | Nombre de la subred dentro de la VNet. |
| **`var.resource_group`**         | Grupo de recursos en el que se define la subred. |
| **`var.virtual_network_name`**   | Relación con la red virtual a la que pertenece la subred. |
| **`address_prefixes = [var.subnet_cidr]`** | Define el rango de direcciones IP asignado a la subred (`10.0.1.0/28`), optimizando el uso de IPs. |

#### Fichero `security.tf`

El fichero `security.tf` del módulo de la máquina virtual recoge los siguientes recursos:

- *Grupo de Seguridad de Red (NSG)* → Gestiona las reglas de tráfico para la máquina virtual.  
- *Reglas de Seguridad (Security Rules)* → Permiten o bloquean tráfico en puertos específicos.

##### Grupo de Seguridad de Red (NSG)

```hcl title="security.tf"
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.vm_name}-nsg"
  resource_group_name = var.resource_group
  location            = var.location
}
```

| **Parámetro**                   | **Descripción** |
|----------------------------------|--------------------------------|
| **`var.vm_name`**                | Nombre del grupo de seguridad, vinculado a la VM. |
| **`var.resource_group`**         | Grupo de recursos donde se crea el NSG. |
| **`var.location`**               | Región de Azure donde se despliega el NSG. |


##### Regla para permitir SSH (Puerto 22)

```hcl title="security.tf"
resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "Allow-SSH"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.vm_nsg.name
}
```

| **Parámetro**                   | **Descripción** |
|----------------------------------|--------------------------------|
| **`priority = 1000`**            | Asigna una prioridad alta para esta regla. |
| **`direction = "Inbound"`**      | Define que la regla aplica al tráfico entrante. |
| **`access = "Allow"`**           | Permite el tráfico en el puerto 22. |
| **`protocol = "Tcp"`**           | Especifica que la regla aplica a conexiones TCP. |
| **`destination_port_range = "22"`** | Permite el acceso SSH a la VM. |


##### Regla para permitir HTTP (Puerto 80)

```hcl title="security.tf"
resource "azurerm_network_security_rule" "allow_http" {
  name                        = "Allow-HTTP"
  priority                    = 1010
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.vm_nsg.name
}
```
 
| **Parámetro**                   | **Descripción** |
|----------------------------------|--------------------------------|
| **`priority = 1010`**            | Define la prioridad de la regla para HTTP. |
| **`destination_port_range = "80"`** | Habilita tráfico en el puerto 80 para servir contenido web. |


##### Regla para permitir HTTPS (Puerto 443)

```hcl title="security.tf"
resource "azurerm_network_security_rule" "allow_https" {
  name                        = "Allow-HTTPS"
  priority                    = 1020
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.vm_nsg.name
}
```

| **Parámetro**                   | **Descripción** |
|----------------------------------|--------------------------------|
| **`priority = 1020`**            | Prioridad asignada a la regla HTTPS. |
| **`destination_port_range = "443"`** | Habilita tráfico en el puerto 443 para conexiones seguras. |

---

##### Regla para permitir todo el tráfico de salida

```hcl title="security.tf"
resource "azurerm_network_security_rule" "allow_outbound" {
  name                        = "Allow-All-Outbound"
  priority                    = 900
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.vm_nsg.name
}
```
 
| **Parámetro**                   | **Descripción** |
|----------------------------------|--------------------------------|
| **`priority = 900`**             | Define una prioridad más baja que las reglas de entrada. |
| **`direction = "Outbound"`**     | Aplica la regla al tráfico saliente. |
| **`access = "Allow"`**           | Permite que la VM se comunique con otros servicios. |
| **`protocol = "*"`**             | Permite cualquier protocolo. |
| **`destination_port_range = "*"`** | No restringe los puertos de destino. |

### Kubernetes service (AKS)

La infraestructura del **Azure Kubernetes Service (AKS)** se ha definido en **Terraform** dentro de un módulo independiente para asegurar una correcta organización y reutilización del código. Este módulo define los recursos necesarios para desplegar un clúster de Kubernetes gestionado por Azure.

```bash
terraform/
│── terraform.tfvars        # Variables globales del despliegue
│── main.tf                 # Llamada a módulos y recursos principales
│── modules/
│   ├── aks/                # Módulo de Kubernetes Service (AKS)
│   │   ├── main.tf         # Definición del clúster de Kubernetes
│   │   ├── outputs.tf      # Variables de salida (Cluster ID, Node Pool ID)
│   │   └── variables.tf    # Definición de variables del módulo
```

#### Fichero `main.tf`

El fichero `main.tf` del módulo de AKS incluye los siguientes recursos:

- **Clúster de Kubernetes (AKS)** → Crea una instancia de **Azure Kubernetes Service** con un *node pool* por defecto y acceso RBAC habilitado.
- **Role Assignment para ACR** → Permite a AKS acceder al **Azure Container Registry (ACR)** para extraer imágenes de contenedores.

##### Clúster de Kubernetes (AKS)

```hcl title="main.tf"
resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.aks_name
  location            = var.location
  resource_group_name = var.resource_group
  dns_prefix          = var.dns_prefix
  sku_tier            = "Standard"

  default_node_pool {
    name            = "default"
    node_count      = var.node_count
    vm_size         = var.vm_size
    os_disk_size_gb = 30
  }

  identity {
    type = "SystemAssigned"
  }

  role_based_access_control_enabled = true

  tags = var.tags
}
```

| **Parámetro**                   | **Descripción** |
|----------------------------------|--------------------------------|
| **`var.aks_name`**               | Nombre del clúster de AKS. |
| **`var.resource_group`**         | Grupo de recursos donde se despliega el AKS. |
| **`var.location`**               | Región de Azure donde se despliega. |
| **`var.dns_prefix`**             | Prefijo DNS único del clúster. |
| **`sku_tier = "Standard"`**      | Define el nivel del servicio de Kubernetes. |
| **`default_node_pool`**          | Define el grupo de nodos (*Node Pool*) que ejecutará los contenedores. |
| **`var.node_count`**             | Número de nodos en el *node pool* por defecto. |
| **`var.vm_size`**                | Tamaño de las máquinas virtuales utilizadas como nodos. |
| **`os_disk_size_gb = 30`**       | Tamaño del disco de cada nodo. |
| **`identity { type = "SystemAssigned" }`** | Se asigna una identidad gestionada para que el clúster pueda autenticarse con otros servicios de Azure. |
| **`role_based_access_control_enabled = true`** | Habilita RBAC para gestionar permisos dentro del clúster. |
| **`var.tags`**                   | Etiquetas para organización y gestión dentro de Azure. |

##### Role Assignment para ACR

```hcl title="main.tf"
resource "azurerm_role_assignment" "acr_pull" {
  scope                = var.acr_id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}
```

| **Parámetro**                   | **Descripción** |
|----------------------------------|--------------------------------|
| **`var.acr_id`**                 | ID del Azure Container Registry asociado al clúster. |
| **`role_definition_name = "AcrPull"`** | Asigna el rol de **AcrPull**, que permite a AKS extraer imágenes de contenedores desde ACR. |
| **`principal_id`**               | Se refiere a la identidad asignada al clúster de AKS para la autenticación con ACR. |