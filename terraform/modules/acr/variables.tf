# Nombre del grupo de recursos donde se creará ACR
variable "resource_group" {
  description = "El nombre del grupo de recursos"
  type        = string
}

# Ubicación de Azure donde se creará ACR
variable "location" {
  description = "Región de Azure"
  type        = string
}

# Nombre del Azure Container Registry
variable "acr_name" {
  description = "Nombre del registro de contenedores en Azure"
  type        = string
}
