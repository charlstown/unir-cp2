# Arquitectura

Esta sección describe la infraestructura desplegada en Azure, estructurado de la siguiente manera:

- [Diagrama general](#diagrama-general)
- [Infraestrutura](#infraestructura)
- [Configuración de la infraestructura](#configuracion-de-la-infraestructura)

---

## Diagrama general

El siguiente diagrama representa la infraestructura desplegada con Terraform y configurada con Ansible, incluyendo una máquina virtual con un contenedor Podman y un clúster AKS, ambos obteniendo imágenes desde un Azure Container Registry (ACR).

![Arquitectura](../assets/drawio/cp2-arquitectura.png){ .only-pdf }
![Arquitectura](../assets/drawio/cp2-arquitectura.drawio)

*Figura 1: Diagrama de la arquitectura desplegada en Azure (Elaboración propia con [draw.io](./referencias.md#herramientas-usadas)).*
{ .cita }

## Infraestructura

A continuación se describen los diferentes componentes de la infraestructura desplegados con terraform y la justificación de sus configuraciones.

### Container registry

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

#### Definición de la Máquina Virtual

La máquina virtual está configurada en **Azure** y la infraestructura de la máquina virtual se ha organizado en un módulo dentro de **Terraform**

```hcl title="main.tf"
# Public IP
resource "azurerm_public_ip" "vm_public_ip" {
  name                = "${var.vm_name}-public-ip"
  resource_group_name = var.resource_group
  location            = var.location
  allocation_method   = "Static"
}

# Network Interface
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
}

# Virtual Machine
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
}
```

- Se ha elegido **Ubuntu 22.04 LTS (Gen2)** como sistema operativo, basado en la imagen oficial de **Canonical**.
- La máquina está configurada para autenticación por **clave SSH**, evitando contraseñas.
- Se asigna una **interfaz de red**, conectada a una **subred dentro de una VNet**.
- Se utiliza un disco gestionado con almacenamiento **Standard_LRS** para optimizar costes.

#### Redes de la Máquina Virtual  

La red virtual y la subred asociada a la máquina virtual están definidas en **`network.tf`**, garantizando su conectividad.  

```hcl title="network.tf"
# Definición de la Virtual Network (VNet)
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.resource_group
  location            = var.location
  address_space       = ["10.0.0.0/16"]
}

# Subred dentro de la VNet
resource "azurerm_subnet" "subnet" {
  name                 = var.subnet_name
  resource_group_name  = var.resource_group
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [var.subnet_cidr]
}

# Interfaz de red de la VM
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
}

# Dirección IP pública de la VM
resource "azurerm_public_ip" "vm_public_ip" {
  name                = "${var.vm_name}-public-ip"
  resource_group_name = var.resource_group
  location            = var.location
  allocation_method   = "Static"
}
```

- Se define una **VNet (`vnet-weu-cp2`)** con un **espacio de direcciones `10.0.0.0/16`**.  
- La **subred (`subnet-weu-cp2`)** tiene un rango más reducido `10.0.1.0/28` para optimizar la asignación de IPs.  
- La VM obtiene una **IP pública estática**, permitiendo acceso remoto controlado.

#### Seguridad de la Máquina Virtual  

El **grupo de seguridad (NSG)** controla el tráfico de entrada y salida de la VM. En **`security.tf`**, se han definido reglas explícitas para habilitar el acceso SSH, HTTP y HTTPS.  

```hcl title="security.tf"
# Definición del Network Security Group (NSG)
resource "azurerm_network_security_group" "vm_nsg" {
  name                = "${var.vm_name}-nsg"
  resource_group_name = var.resource_group
  location            = var.location
}

# Regla para permitir SSH (puerto 22)
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

# Regla para permitir HTTP (puerto 80)
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

# Regla para permitir HTTPS (puerto 443)
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

# Regla para permitir todo el tráfico de salida
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

- Se permite acceso **SSH (22) solo a usuarios autenticados**.  
- Se abren los **puertos HTTP (80) y HTTPS (443)** para servir contenido web.  
- Se garantiza que la VM pueda **salir a internet sin restricciones**, útil para actualizaciones o conexión a otros servicios.  


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


## Configuración de la infraestructura

A continuación se describen las configuraciones aplicadas a la infraestructura desplegada, realizadas con Ansible, y la justificación de cada una de ellas.

### Configuración de la VM

### Configuración del AKS