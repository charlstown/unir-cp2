# Salida con la dirección IP privada de la VM
output "vm_public_ip" {
  value = module.virtual_machine.vm_public_ip
}

# Salida con la URL del ACR
output "acr_login_server" {
  value = module.container_registry.acr_login_server
}