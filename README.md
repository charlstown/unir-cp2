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

## Ejecución del codigo

### 1. Despliegue de la infraestructura

1. Accede al directorio de terraform en el repositorio e inicializa terraform.

    ```sh
    cd terraform
    terraform init
    ```
    Output: `Terraform has been successfully initialized!`
2. Ejecuta la validación de los ficheros generados con el siguiente comando:

    ```sh
    terraform validate
    ```
    output: `Success! The configuration is valid.`
3. Despliega la infraestructura

    ```sh
    terraform apply --auto-approve
    ```

### 2. Publicación de la imagen

La publicación de la imagen se realiza mediante el action [Publish release to ACR](https://github.com/charlstown/unir-cp2/actions/workflows/publish-release.yml) en el mismo repositorio de github.

1. Rellenar los datos del formulario del workflow con username y pwd del ACR desplegado en Azure.

    ![Workflow form](./docs/assets/images/run-workflow-form.png)

2. Ejecutar workflow y validar la correcta ejecución del job

    ![Workflow run](./docs/assets/images/job-logs.png)

### 3. Configuración de VM con ansible

1. Comprobar conexión a la VM por SSH

    ```sh
    ssh -i ~/.ssh/az_unir_rsa azureuser@<YOUR_VM_PUBLIC_IP>
    exit
    ```
2. Exportar secrets en el environment

    ```sh
    export ACR_USERNAME="your_acr_username"
    export ACR_PASSWORD="your_acr_password"
    ```
3. Ejecutar ansible apuntando a la VM

    ```sh
    ansible-playbook -i inventory.ini install_podman_run_container.yml --extra-vars "@vars.yml"
    ```
4. Comprobar que el contenedor está ejecutándose

    ```sh
    ssh -i ~/.ssh/az_unir_rsa azureuser@<YOUR_VM_PUBLIC_IP>
    podman ps
    ```

---

📌 **Autor**: *[@charlstown](https://github.com/charlstown)*  
📌 **Fecha**: *23-03-2025*
