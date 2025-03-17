# :simple-ansible: Configuración de la infraestructura

A continuación se describen las configuraciones aplicadas a la infraestructura desplegada, automatizadas con Ansible, y la justificación de cada una de ellas.

## Imágenes contenerizadas

### Imágen sin persistencia para la VM

La imagen utilizada en el contenedor Podman dentro de la máquina virtual se basa en **MkDocs**, una librería de documentación escrita en Python. Esta herramienta permite generar sitios estáticos a partir de archivos Markdown, facilitando la creación y publicación de documentación técnica [(MkDocs, s.f.)](./referencias.md#herramientas-usadas). La imagen generada en este ejercicio contiene la documentación del propio proyecto, asegurando que el contenido se pueda visualizar de manera estructurada en un navegador.

Además, se ha utilizado el tema **Material for MkDocs**, que añade una interfaz moderna y varias opciones de personalización [(Squidfunk, s.f.)](./referencias.md#herramientas-usadas).

La documentación también está disponible a través de **GitHub Pages**, lo que permite su acceso incluso cuando la infraestructura de Azure no está desplegada. Se puede visualizar en el siguiente enlace:  

[:material-file-document: Ver documentación en GitHub Pages](https://charlstown.github.io/unir-cp2)  

### Imágen con persistencia para el AKS

## Configuración del ACR

Para configurar el ACR se publicarán dos imágenes contenerizadas: una corresponde a un sitio estático en Nginx, que será desplegado en una máquina virtual con Podman, y la otra es una aplicación con persistencia que será ejecutada en un contenedor dentro de Azure Kubernetes Service (AKS).

Este proyecto permite la publicación de las imágenes en el ACR de dos maneras:

- Publicación mediante Ansible.
- Publicación manual mediante Github Actions (fuera de alcance)

### Publicación mediante Ansible

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



### Instalar Podman

```yaml title="install.yml"
---
- name: Install Podman
  apt:
    name: podman
    state: present
    update_cache: no  # Avoids unnecessary update
```

### Construir la imagen

```yaml title="build.yml"
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
    cmd: podman build -t "{{ image_name }}:{{ image_tag }}" -f /opt/unir-cp2/Dockerfile.docs
    chdir: "/opt/unir-cp2"
```

### Publicar la imagen en ACR



#### Generación de la Imagen  

La imagen se genera a partir de la documentación escrita en MkDocs, transformándola en un sitio web estático y empaquetándola en un contenedor. Esta imagen se construye y publica mediante dos métodos:  

1. **Workflow de GitHub:** Se ha añadido un workflow en `.github/workflows` llamado [:material-file-document: `Publish docs to ACR`](https://github.com/charlstown/unir-cp2/blob/main/.github/workflows/publish-release.yml), que permite generar y publicar la imagen en el ACR. 

2. **Ejecución con Ansible:** Durante la configuración de la máquina virtual, Ansible ejecuta un playbook con el mismo proceso que el workflow de GitHub para generar y publicar la imagen en el ACR.

El proceso detallado de despliegue de la imagen puede consultarse en el siguiente apartado de esta memoria: [:material-file-document: Sección de Despliegue](./despliegue.md).


## Configuración de la VM

## Configuración del AKS