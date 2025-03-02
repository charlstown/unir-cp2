# Salida con la dirección IP publica de la VM
output "vm_public_ip" {
  value = module.virtual_machine.vm_public_ip
}

# Salida con la URL del ACR
output "acr_login_server" {
  value = module.container_registry.acr_login_server
}

# Salida con el nombre de usuario del ACR
output "acr_username" {
  description = "ACR Admin Username"
  value       = azurerm_container_registry.acr.admin_username
}

# Salida con la contraseña del ACR
output "acr_password" {
  description = "ACR Admin Password"
  value       = azurerm_container_registry.acr.admin_password
  sensitive   = true
}
