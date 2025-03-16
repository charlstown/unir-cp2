# Salida con la URL de acceso al ACR
output "acr_login_server" {
  description = "Servidor de inicio de sesión del ACR"
  value       = azurerm_container_registry.acr.login_server
}

output "acr_username" {
  description = "ACR Admin Username"
  value       = azurerm_container_registry.acr.admin_username
}

output "acr_password" {
  description = "ACR Admin Password"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}

output "acr_id" {
  description = "The ID of the Azure Container Registry"
  value       = azurerm_container_registry.acr.id
}