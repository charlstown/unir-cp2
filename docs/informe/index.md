# Informe

Este informe documenta la entrega del Caso Práctico 2 de la asignatura **DevOps & Cloud** del **programa avanzado DevOps** de la UNIR. El contenido del informe se estructura en las siguientes secciones:  

- **[Arquitectura](./arquitectura/index.md)**: Descripción de los componentes desplegados y su configuración.  
- **[Despliegue](./despliegue.md)**: Ejecución práctica de la infraestructura y su configuración.  
- **[Evidencias](./evidencias.md)**: Recopilación de pruebas de funcionamiento y validaciones.  
- **[Licencia](./licencia.md)**: Definición del marco legal de uso.  
- **[Referencias](./referencias.md)**: Fuentes utilizadas en el desarrollo del ejercicio.  

Para la generación del informe, se ha utilizado MkDocs, una librería de Python para la creación de documentación técnica [(MkDocs, s.f.)](./referencias.md#herramientas-usadas), junto con el plugin WithPDF, que permite la exportación a formato PDF [(WithPDF, s.f.)](./referencias.md#herramientas-usadas). Esta elección responde a la naturaleza del caso práctico, en el que una de las tareas consiste en desplegar una imagen estática de una web en Nginx sin persistencia. Dado que MkDocs genera HTML estático, se ha integrado su uso dentro del ejercicio para la documentación y su despliegue.

## :material-file-code: Codigo fuente

[:simple-git: Acceso al repositorio](https://github.com/charlstown/unir-cp2){ .md-button }

### Estructura del repositorio

El proyecto se organiza en tres grandes bloques: infraestructura, despliegue y documentación. A continuación se resume su estructura principal:

```
📦 repo-root
├── terraform/        # Código para el despliegue de la infraestructura (ACR, VM, AKS)
├── ansible/          # Playbooks y roles para configurar la VM y desplegar en AKS
├── docs/             # Documentación del proyecto (MkDocs)
├── site/             # Sitio estático generado de la documentación
├── setup.sh          # Script para exportar variables tras despliegue
├── mkdocs.yml        # Configuración de MkDocs
├── Dockerfile.docs   # Dockerfile para generar la imagen de documentación
├── requirements.txt  # Dependencias de Python
├── README.md         # Descripción general del proyecto
└── LICENSE           # Licencia del repositorio
```
