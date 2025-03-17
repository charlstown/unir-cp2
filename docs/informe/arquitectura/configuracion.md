# :simple-ansible: Configuración de la infraestructura

A continuación se describen las configuraciones aplicadas a la infraestructura desplegada, automatizadas con Ansible, y la justificación de cada una de ellas.

## Imágenes contenerizadas

### Imágen sin persistencia para la VM

La imagen utilizada en el contenedor Podman dentro de la máquina virtual se basa en **MkDocs**, una librería de documentación escrita en Python. Esta herramienta permite generar sitios estáticos a partir de archivos Markdown, facilitando la creación y publicación de documentación técnica [(MkDocs, s.f.)](./referencias.md#herramientas-usadas). La imagen generada en este ejercicio contiene la documentación del propio proyecto, asegurando que el contenido se pueda visualizar de manera estructurada en un navegador.

Además, se ha utilizado el tema **Material for MkDocs**, que añade una interfaz moderna y varias opciones de personalización [(Squidfunk, s.f.)](./referencias.md#herramientas-usadas).

La documentación también está disponible a través de **GitHub Pages**, lo que permite su acceso incluso cuando la infraestructura de Azure no está desplegada. Se puede visualizar en el siguiente enlace:  

[:material-file-document: Ver documentación en GitHub Pages](https://charlstown.github.io/unir-cp2)  

### Imágen con persistencia para el AKS

Content WIP.

## Configuración con Ansible 

Para la configuración y automatización del despliegue en la infraestructura se ha utilizado Ansible, organizando las tareas en roles específicos, siguiendo las buenas prácticas recomendadas en la documentación oficial de Ansible [Ansible. (s.f.-a)](../referencias.md).

La ejecución de los archivos está estructurada de la siguiente manera:

```bash
ansible
├── hosts.tmpl           # Plantilla del inventario dinámico
├── playbook.yml         # Orquesta todos los roles
├── publish_images.yml   # Publica imágenes en el ACR
├── vm_deployment.yml    # Despliega en el contenedor de la VM
├── aks_deployment.yml   # Despliega en el contenedor del AKS
├── roles
│   ├── acr              # Rol para la publicación en el ACR
│   └── vm               # Rol para la configuración de la VM
│   └── aks              # Rol para la configuración de la VM
├── secrets.yml          # Variables sensibles
└── vars.yml             # Variables generales del despliegue
```

- **ACR**: Gestiona la publicación de imágenes en **Azure Container Registry (ACR)**, construyendo y empujando imágenes desde la VM y desde la máquina local.  
- **VM**: Configura la máquina virtual, instalando **Podman**, desplegando el contenedor con **MkDocs**, gestionando autenticaciones y asegurando la persistencia con **Systemd**.  
- **AKS** *(no presente en este esquema, pero estructurable de forma similar)*: Se encargaría de desplegar aplicaciones en **Azure Kubernetes Service (AKS)**.

### Rol ACR

Para configurar el ACR se publicarán dos imágenes contenerizadas: una corresponde a un sitio estático en Nginx, que será desplegado en una máquina virtual con Podman, y la otra es una aplicación con persistencia que será ejecutada en un contenedor dentro de Azure Kubernetes Service (AKS).

Este proyecto permite la publicación de las imágenes en el ACR de dos maneras:

- Publicación mediante Ansible.
- Publicación manual mediante Github Actions (fuera de alcance).

#### Publicación mediante Ansible

Para la publicación usando Ansible se ha generado un rol llamado `acr` que contiene todas las tareas necesarias y se estructura de la siguiente manera:

```sh
ansible/
├── roles/
│   ├── acr/                        # Rol para gestionar ACR en Ansible
│   │   ├── tasks/                  # Tareas que se ejecutan en el ACR
│   │   │   ├── main.yml            # Inclusión de todas las tareas
│   │   │   ├── install.yml         # Instala podman en la VM
│   │   │   ├── build_docs.yml      # Construcción de las imágenes
│   │   │   ├── login.yml           # Iniciar sesión en ACR
│   │   │   ├── push_mkdocs.yml     # Publicación de mkdocs en ACR
│   │   │   └── push_stackedit.yml  # Publicación de stackedit en ACR
│   │   └── vars/                   # Variables específicas del rol
│   │       └── main.yml            # Configuración de parámetros
```

El fichero `tasks/main.yml` dentro del rol acr, gestiona la configuración y publicación de imágenes en la máquina virtual y el Azure Container Registry (ACR).

```yaml title="main.yml"
---
- name: Install Podman on the VM
  include_tasks: install.yml

- name: Build MkDocs image
  include_tasks: build_docs.yml

- name: Login into ACR from the VM
  include_tasks: login.yml

- name: Push mkdocs image to ACR from the VM
  include_tasks: push_mkdocs.yml

- name: Push stackedit image to ACR from localhost
  include_tasks: push_stackedit.yml
```

#### Instalar Podman

Esta tarea instala Podman en la máquina virtual asegurándose de que esté disponible en el sistema. Además, actualiza la caché de paquetes antes de la instalación.

```yaml title="install.yml"
---
- name: Install Podman
  apt:
    name: podman
    state: present
    update_cache: yes
```

#### Construir la imagen mkdocs

Clona el repositorio del proyecto en la máquina virtual, instala dependencias necesarias para MkDocs y WeasyPrint, construye el sitio estático de MkDocs y genera una imagen de contenedor con Podman basada en el `Dockerfile.docs`.

```yaml title="build_docs.yml"
---
- name: Ensure repository is present on the VM
  git:
    repo: "https://github.com/charlstown/unir-cp2.git"
    dest: "/opt/unir-cp2"
    version: main

- name: Install dependencies for MkDocs
  apt:
    name:
      - python3-pip
    state: present
    update_cache: no
  become: yes

- name: Install required system dependencies for WeasyPrint
  apt:
    name:
      - libpango1.0-0
      - libpangocairo-1.0-0
      - libcairo2
    state: present
    update_cache: no
  become: yes

- name: Install project dependencies
  pip:
    requirements: "/opt/unir-cp2/requirements.txt"

- name: Build MkDocs static site
  command:
    cmd: mkdocs build
    chdir: "/opt/unir-cp2"

- name: Build Podman image on the VM
  command:
    cmd: podman build -t "{{ image_name_docs }}:{{ image_tag_docs }}" -f /opt/unir-cp2/Dockerfile.docs
    chdir: "/opt/unir-cp2"
```

#### Login en el ACR

Realiza la autenticación en Azure Container Registry (ACR) desde la máquina virtual utilizando Podman, empleando credenciales de usuario y contraseña.

```yaml title="login_acr.yml"
---
- name: Log in to ACR from the VM
  command: >
    podman login {{ acr_login_server }} 
    -u {{ acr_username }} 
    --password {{ acr_password }}
```

#### Publicar imagen `mkdocs-nginx`

Etiqueta la imagen generada de MkDocs con el formato adecuado para ACR y la sube al registro de contenedores de Azure desde la máquina virtual.

```yaml title="push_mkdocs.yml"
---
# Push MkDocs image
- name: Tag MkDocs image for ACR
  command: >
    podman tag {{ image_name_docs }}:{{ image_tag_docs }} 
    {{ acr_login_server }}/{{ image_name_docs }}:{{ image_tag_docs }}

- name: Push MkDocs image to ACR from the VM
  command: >
    podman push {{ acr_login_server }}/{{ image_name_docs }}:{{ image_tag_docs }}

```

#### Publicar imagen `stackedit`

Descarga la imagen `stackedit-base` desde Docker Hub, la etiqueta para el ACR y finalmente la sube al registro de Azure.

```yaml title="push_stackedit.yml"
---
- name: Pull StackEdit image from Docker Hub
  command: >
    podman pull docker.io/benweet/stackedit-base:latest
  become: yes

- name: Tag StackEdit image for ACR
  command: >
    podman tag docker.io/benweet/stackedit-base:latest {{ acr_name }}.azurecr.io/{{ image_name_stackedit }}:{{ image_tag_stackedit }}
  become: yes

- name: Push StackEdit image to ACR
  command: >
    podman push {{ acr_name }}.azurecr.io/{{ image_name_stackedit }}:{{ image_tag_stackedit }}
  become: yes
```


### Rol VM

### Rol AKS