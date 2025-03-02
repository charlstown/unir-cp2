# 🚀 Unir Caso Práctico 2

Este repositorio contiene la solución del **Caso Práctico 2**, en el cual se ha desplegado una infraestructura en **Microsoft Azure** de forma automatizada utilizando **Terraform** y **Ansible**. Se incluyen configuraciones para la creación de recursos en la nube, instalación de servicios y despliegue de aplicaciones en contenedores con almacenamiento persistente.

## 🎯 Objetivos

- Crear infraestructura en **Azure** de forma automatizada.
- Gestionar la configuración con **Ansible**.
- Desplegar aplicaciones en contenedores sobre **Linux y AKS**.
- Implementar almacenamiento persistente en **Kubernetes**.

## 🗂️ Estructura del repositorio

```
📦 repo-root
├── ansible
│   ├── deploy.sh       # Script de despliegue con Ansible
│   ├── hosts           # Inventario de servidores
│   └── playbook.yml    # Playbook principal de Ansible
│
├── terraform
│   ├── vars.tf         # Variables de configuración
│   ├── main.tf         # Configuración principal de Terraform
│   └── recursos.tf     # Definición de recursos en Azure
```

## ⚙️ Tecnologías utilizadas

- **Terraform**: Creación de infraestructura en Azure (ACR, VM, AKS).
- **Ansible**: Configuración automática de servicios y despliegue de aplicaciones.
- **Podman**: Contenedorización de aplicaciones en la VM.
- **Kubernetes (AKS)**: Orquestación de aplicaciones con almacenamiento persistente.

---

📌 **Autor**: *[@charlstown](https://github.com/charlstown)*  
📌 **Fecha**: *23-03-2025*
