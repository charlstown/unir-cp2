# Despliegue

A continuación, se explica cómo reproducir los pasos necesarios para llevar a cabo el caso práctico. Se detallan las instrucciones para:

- [1. Despliegue de la infraestructura](#1-despliegue-de-la-infraestructura)
- [2. Publicación de la imagen](#2-publicacion-de-la-imagen)
- [3. Configuración de VM](#3-configuración-de-vm)

---

## 1. Despliegue de la infraestructura

El despliegue de la infraestructura se realiza con Terraform desde la máquina local, asegurando que la configuración es válida antes de aplicar los cambios y provisionar los recursos necesarios.

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

## 2. Publicación de la imagen

La publicación de la imagen se automatiza mediante el workflow [`Publish release to ACR`](https://github.com/charlstown/unir-cp2/actions/workflows/publish-release.yml) de GitHub Actions, que envía la imagen al Azure Container Registry (ACR). Para ello, se deben proporcionar las credenciales adecuadas y validar la ejecución del proceso.

1. Rellenar los datos del formulario del workflow con username y pwd del ACR desplegado en Azure.

    ![Workflow form](../assets/images/run-workflow-form.png)

2. Ejecutar workflow y validar la correcta ejecución del job

    ![Workflow run](../assets/images/job-logs.png)

## 3. Configuración de VM

La configuración de la VM se llevará a cabo desde la máquina local utilizando Ansible, accediendo por SSH para realizar comprobaciones y garantizar el correcto despliegue del entorno.

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