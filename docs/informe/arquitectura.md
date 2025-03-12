# Arquitectura

En esa sección se muestra


---

## Diagrama general

El siguiente diagrama representa la infraestructura desplegada con Terraform y configurada con Ansible, incluyendo una máquina virtual con un contenedor Podman y un clúster AKS, ambos obteniendo imágenes desde un Azure Container Registry (ACR).

![Arquitectura](../assets/drawio/cp2-arquitectura.png){ .only-pdf }
![Arquitectura](../assets/drawio/cp2-arquitectura.drawio)

*Figura 1: Diagrama de la arquitectura desplegada en Azure (Elaboración propia con [draw.io](./referencias.md#herramientas-usadas)).*
{ .cita }

## Componentes de la arquitectura

### Container registry

### Máquina virtual

### Kubernetes service

## Imágenes contenerizadas

### Imágen sin persistencia para la VM

La imagen utilizada en el contenedor Podman dentro de la máquina virtual se basa en **MkDocs**, una librería de documentación escrita en Python. Esta herramienta permite generar sitios estáticos a partir de archivos Markdown, facilitando la creación y publicación de documentación técnica [(MkDocs, s.f.)](./referencias.md#herramientas-usadas). La imagen generada en este ejercicio contiene la documentación del propio proyecto, asegurando que el contenido se pueda visualizar de manera estructurada en un navegador.

Además, se ha utilizado el tema **Material for MkDocs**, que añade una interfaz moderna y varias opciones de personalización [(Squidfunk, s.f.)](./referencias.md#herramientas-usadas).

#### Publicación en GitHub Pages  

La documentación también está disponible a través de **GitHub Pages**, lo que permite su acceso incluso cuando la infraestructura de Azure no está desplegada. Se puede visualizar en el siguiente enlace:  

[:material-file-document: Ver documentación en GitHub Pages](https://charlstown.github.io/unir-cp2/informe/despliegue/)  

#### Generación de la Imagen  

La imagen se genera a partir de la documentación escrita en MkDocs, transformándola en un sitio web estático y empaquetándola en un contenedor. Esta imagen se construye y publica mediante dos métodos:  

1. **Workflow de GitHub:** Se ha añadido un workflow en `.github/workflows` llamado [:material-file-document: `Publish docs to ACR`](https://github.com/charlstown/unir-cp2/blob/main/.github/workflows/publish-release.yml), que permite generar y publicar la imagen en el ACR. 

2. **Ejecución con Ansible:** Durante la configuración de la máquina virtual, Ansible ejecuta un playbook con el mismo proceso que el workflow de GitHub para generar y publicar la imagen en el ACR.

El proceso detallado de despliegue de la imagen puede consultarse en el siguiente apartado de esta memoria: [:material-file-document: Sección de Despliegue](./despliegue.md).

### Imágen con persistencia para el AKS
