# Arquitectura

Esta sección describe la infraestructura desplegada en Azure, estructurado de la siguiente manera:

- [:simple-diagramsdotnet: Diagrama general](#diagrama-general)
- [:simple-terraform: Infraestrutura](#infraestructura)
- [:simple-ansible: Configuración de la infraestructura](#configuracion-de-la-infraestructura)

---

## :simple-diagramsdotnet: Diagrama general

El siguiente diagrama representa la infraestructura desplegada con Terraform y configurada con Ansible, incluyendo una máquina virtual con un contenedor Podman y un clúster AKS, ambos obteniendo imágenes desde un Azure Container Registry (ACR).

![Arquitectura](../assets/drawio/cp2-arquitectura.png){ .only-pdf }
![Arquitectura](../assets/drawio/cp2-arquitectura.drawio)

*Figura 1: Diagrama de la arquitectura desplegada en Azure (Elaboración propia con [draw.io](./referencias.md#herramientas-usadas)).*
{ .cita }

## :simple-terraform: Infraestructura

A continuación se describen los diferentes componentes de la infraestructura desplegados con terraform y la justificación de sus configuraciones.

### Container registry

La infraestructura de **Azure Container Service(ACR)** se ha definido utilizando **Terraform**, organizando los recursos en módulos separados para mejorar la modularidad y reutilización del código. A continuación, se presentan los archivos principales que definen el despliegue:

```bash
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

### Kubernetes service

### Imágenes contenerizadas

#### Imágen sin persistencia para la VM

La imagen utilizada en el contenedor Podman dentro de la máquina virtual se basa en **MkDocs**, una librería de documentación escrita en Python. Esta herramienta permite generar sitios estáticos a partir de archivos Markdown, facilitando la creación y publicación de documentación técnica [(MkDocs, s.f.)](./referencias.md#herramientas-usadas). La imagen generada en este ejercicio contiene la documentación del propio proyecto, asegurando que el contenido se pueda visualizar de manera estructurada en un navegador.

Además, se ha utilizado el tema **Material for MkDocs**, que añade una interfaz moderna y varias opciones de personalización [(Squidfunk, s.f.)](./referencias.md#herramientas-usadas).

##### Publicación en GitHub Pages  

La documentación también está disponible a través de **GitHub Pages**, lo que permite su acceso incluso cuando la infraestructura de Azure no está desplegada. Se puede visualizar en el siguiente enlace:  

[:material-file-document: Ver documentación en GitHub Pages](https://charlstown.github.io/unir-cp2/informe/despliegue/)  

##### Generación de la Imagen  

La imagen se genera a partir de la documentación escrita en MkDocs, transformándola en un sitio web estático y empaquetándola en un contenedor. Esta imagen se construye y publica mediante dos métodos:  

1. **Workflow de GitHub:** Se ha añadido un workflow en `.github/workflows` llamado [:material-file-document: `Publish docs to ACR`](https://github.com/charlstown/unir-cp2/blob/main/.github/workflows/publish-release.yml), que permite generar y publicar la imagen en el ACR. 

2. **Ejecución con Ansible:** Durante la configuración de la máquina virtual, Ansible ejecuta un playbook con el mismo proceso que el workflow de GitHub para generar y publicar la imagen en el ACR.

El proceso detallado de despliegue de la imagen puede consultarse en el siguiente apartado de esta memoria: [:material-file-document: Sección de Despliegue](./despliegue.md).

#### Imágen con persistencia para el AKS


## :simple-ansible: Configuración de la infraestructura

A continuación se describen las configuraciones aplicadas a la infraestructura desplegada, realizadas con Ansible, y la justificación de cada una de ellas.

### Configuración de la VM

### Configuración del AKS