# :simple-ansible: Configuración de la infraestructura

A continuación se describen las configuraciones aplicadas a la infraestructura desplegada, automatizadas con Ansible, y la justificación de cada una de ellas.

## Imágenes contenerizadas

### Imágen sin persistencia para la VM

La imagen utilizada en el contenedor Podman dentro de la máquina virtual se basa en **MkDocs**, una librería de documentación escrita en Python. Esta herramienta permite generar sitios estáticos a partir de archivos Markdown, facilitando la creación y publicación de documentación técnica [(MkDocs, s.f.)](./referencias.md#herramientas-usadas). La imagen generada en este ejercicio contiene la documentación del propio proyecto, asegurando que el contenido se pueda visualizar de manera estructurada en un navegador.

Además, se ha utilizado el tema **Material for MkDocs**, que añade una interfaz moderna y varias opciones de personalización [(Squidfunk, s.f.)](./referencias.md#herramientas-usadas).

La documentación también está disponible a través de **GitHub Pages**, lo que permite su acceso incluso cuando la infraestructura de Azure no está desplegada. Se puede visualizar en el siguiente enlace:  

[:material-file-document: Ver documentación en GitHub Pages](https://charlstown.github.io/unir-cp2)  

### Imágen con persistencia para el AKS

La imagen desplegada en el clúster de **AKS** está basada en **StackEdit**, una aplicación web de código abierto que permite editar y guardar documentos en formato Markdown directamente desde el navegador. Esta herramienta es ideal para la toma de notas técnicas o redacción de documentación rápida, ya que ofrece previsualización en tiempo real y sincronización con almacenamiento local y en la nube [(StackEdit, s.f.)](./referencias.md#herramientas-usadas).

Para este ejercicio se ha utilizado la imagen pública disponible en Docker Hub: [`benweet/stackedit`](https://hub.docker.com/r/benweet/stackedit), la cual se despliega en un contenedor dentro de Kubernetes con un volumen persistente asociado. Esto garantiza que el contenido creado por el usuario, como notas o documentos, **no se pierde** aunque el contenedor se reinicie o se reprograme, validando así la persistencia de los datos en un entorno dinámico.

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

!!! example ""

    Puedes ver las evidencias de este rol en el [:material-monitor-screenshot: siguiente enlace](../evidencias.md#publicacion-de-imagenes-mediante-ansible).

Este proyecto permite la publicación de las imágenes en el ACR de dos maneras:

- Publicación mediante Ansible.
- Publicación manual mediante Github Actions (fuera de alcance).

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

#### Construir imagen mkdocs

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

Para la publicación usando Ansible se ha generado un rol llamado `vm` que contiene todas las tareas necesarias y se estructura de la siguiente manera:

```sh
ansible/
├── roles
│   ├── vm
│   │   ├── handlers
│   │   │   └── main.yml
│   │   ├── tasks
│   │   │   ├── auth.yml
│   │   │   ├── container.yml
│   │   │   ├── main.yml
│   │   │   └── systemd.yml
│   │   └── vars
│   │       └── main.yml
```

!!! example ""

    Puedes ver las evidencias de este rol en el [:material-monitor-screenshot: siguiente enlace](../evidencias.md#despliegue-en-la-vm).

El fichero `tasks/main.yml` dentro del rol acr, gestiona la configuración y publicación de imágenes en la máquina virtual y el Azure Container Registry (ACR).

```yaml title="main.yml"
- name: Include authentication setup
  import_tasks: auth.yml

- name: Include container deployment
  import_tasks: container.yml

- name: Include systemd configuration
  import_tasks: systemd.yml
```

#### Autenticación básica

En esta tarea se configura autenticación básica en Nginx mediante `htpasswd`, asegurando que solo usuarios autorizados puedan acceder. Se instala Apache Utils, se crea el directorio de autenticación y se genera un archivo de credenciales.


```yaml
---
- name: Install Apache Utils for htpasswd
  apt:
    name: apache2-utils
    state: present
  become: yes

- name: Ensure authentication directory exists
  file:
    path: /etc/nginx/auth
    state: directory
    mode: '0755'

- name: Load secure variables
  include_vars: secrets.yml

- name: Generate htpasswd file
  command: htpasswd -bc /etc/nginx/auth/htpasswd.users charlstown "{{ site_pwd }}"
  args:
    creates: /etc/nginx/auth/htpasswd.users
```


#### Desplegar contenedor

En esta tarea se inicia sesión en el ACR para descargar la imagen del contenedor y se ejecuta con soporte SSL y autenticación básica, vinculando el archivo de credenciales generado en el paso anterior.

```yaml
---
- name: Log into Azure Container Registry (ACR)
  containers.podman.podman_login:
    registry: "{{ acr_name }}.azurecr.io"
    username: "{{ acr_username }}"
    password: "{{ acr_password }}"

- name: Run container from ACR image with SSL and Basic Auth
  containers.podman.podman_container:
    name: mkdocs_container
    image: "{{ acr_name }}.azurecr.io/{{ image_name }}:{{ image_tag }}"
    state: started
    restart_policy: always
    ports:
      - "443:443"
    volume:
      - "/etc/nginx/auth/htpasswd.users:/etc/nginx/.htpasswd:ro"
```


#### Disponibilidad como servicio

En esta tarea se convierte el contenedor en un servicio systemd, esto garantiza la disponibilidad continua del servicio sin intervención manual, ya que systemd lo monitorea y lo vuelve a iniciar si detecta que ha dejado de funcionar.

```yaml
---
- name: Generate systemd service for Podman container
  containers.podman.podman_generate_systemd:
    name: mkdocs_container
    dest: /etc/systemd/system/
    restart_policy: always

- name: Enable and start Podman container systemd service
  systemd:
    name: container-mkdocs_container
    enabled: yes
    state: started
    daemon_reload: yes
```

### Rol AKS

Para el despliegue de la aplicación en el clúster de Kubernetes mediante Ansible se ha generado un rol llamado `aks`, que contiene todas las tareas necesarias y se estructura de la siguiente manera:

```sh
ansible/
├── roles
│   ├── aks
│   │   ├── tasks
│   │   │   ├── acr_auth.yml
│   │   │   ├── deploy.yml
│   │   │   ├── main.yml
│   │   │   ├── namespace.yml
│   │   │   ├── pvc.yml
│   │   │   └── service.yml
│   │   ├── templates
│   │   │   ├── acr-auth.json.j2
│   │   │   ├── deployment.yml.j2
│   │   │   ├── pvc.yml.j2
│   │   │   └── service.yml.j2
│   │   └── vars
│   │       └── main.yml
```

!!! example ""

    Puedes ver las evidencias de este rol en el [:material-monitor-screenshot: siguiente enlace](../evidencias.md#despliegue-en-el-aks).

El fichero `tasks/main.yml` dentro del rol `aks` orquesta todas las tareas necesarias para desplegar la aplicación, incluyendo la creación del namespace, los volúmenes persistentes, el despliegue de los contenedores y el servicio de acceso.

```yaml title="main.yml"
- name: Create Kubernetes Namespace
  import_tasks: namespace.yml

- name: Create ACR Secret in Kubernetes
  import_tasks: acr_auth.yml

- name: Apply PersistentVolumeClaim
  import_tasks: pvc.yml

- name: Deploy Application
  import_tasks: deploy.yml

- name: Create LoadBalancer Service
  import_tasks: service.yml
```

#### Crear Namespace

Esta tarea se encarga de crear el namespace donde se desplegarán todos los recursos de la aplicación dentro del clúster de AKS, asegurando su aislamiento lógico del resto de workloads.

{% raw %}
```yaml title="namespace.yml"
---
- name: Create Kubernetes Namespace
  kubernetes.core.k8s:
    name: "{{ namespace }}"
    api_version: v1
    kind: Namespace
    state: present
```
{% endraw %}

#### Crear secreto en el ACR

Esta tarea crea un `Secret` en el clúster de AKS con las credenciales necesarias para acceder al Azure Container Registry (ACR), permitiendo que Kubernetes pueda descargar imágenes privadas.

{% raw %}
```yaml title="acr_auth.yml"
- name: Create ACR Secret in Kubernetes
  kubernetes.core.k8s:
    state: present
    namespace: "{{ namespace }}"
    definition:
      apiVersion: v1
      kind: Secret
      metadata:
        name: acr-secret
      type: kubernetes.io/dockerconfigjson
      data:
        .dockerconfigjson: "{{ lookup('template', 'acr-auth.json.j2') | from_yaml | to_json | b64encode }}"
```
{% endraw %}

El secreto se genera a partir de la plantilla `acr-auth.json.j2`, que contiene las credenciales codificadas en base64:

{% raw %}
```json title="acr-auth.json.j2"
{
  "auths": {
    "{{ acr_name }}.azurecr.io": {
      "username": "{{ acr_username }}",
      "password": "{{ acr_password }}",
      "auth": "{{ (acr_username + ':' + acr_password) | b64encode }}"
    }
  }
}
```
{% endraw %}

#### Crear volumen persistente

Esta tarea crea un `PersistentVolumeClaim` en el clúster de AKS, necesario para mantener los datos persistentes entre reinicios del contenedor.

{% raw %}
```yaml title="pvc.yml"
- name: Apply PersistentVolumeClaim
  kubernetes.core.k8s:
    state: present
    namespace: "{{ namespace }}"
    definition: "{{ lookup('template', 'pvc.yml.j2') }}"
```
{% endraw %}

La plantilla utilizada define un volumen de 5GiB con acceso en modo lectura-escritura por un único nodo:

{% raw %}
```yaml title="pvc.yml.j2"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: {{ pvc_name }}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```
{% endraw %}

#### Desplegar aplicación

Esta tarea aplica el `Deployment` de Kubernetes necesario para ejecutar la aplicación StackEdit. Se especifica la imagen publicada en el ACR, el puerto interno del contenedor, el volumen persistente y las credenciales de acceso al registro.

{% raw %}
```yaml title="deploy.yml"
- name: Deploy Application
  kubernetes.core.k8s:
    state: present
    namespace: "{{ namespace }}"
    definition: "{{ lookup('template', 'deployment.yml.j2') }}"
```
{% endraw %}

La plantilla del manifiesto define una réplica del contenedor con puerto interno `8080` y volumen montado en `/data`:

{% raw %}
```yaml title="deployment.yml.j2"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: stackedit
spec:
  replicas: 1
  selector:
    matchLabels:
      app: stackedit
  template:
    metadata:
      labels:
        app: stackedit
    spec:
      containers:
      - name: stackedit
        image: "{{ acr_name }}.azurecr.io/{{ image_name_stackedit }}:{{ image_tag_stackedit }}"
        ports:
        - containerPort: 8080
        volumeMounts:
        - name: storage
          mountPath: "/data"
        env:
        - name: ENV_VAR
          value: "example-value"
      volumes:
      - name: storage
        persistentVolumeClaim:
          claimName: {{ pvc_name }}
      imagePullSecrets:
      - name: acr-secret
```
{% endraw %}
