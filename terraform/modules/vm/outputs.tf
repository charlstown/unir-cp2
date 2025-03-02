# Devuelve el ID de la VM creada
output "vm_id" {
  description = "El ID de la máquina virtual"
  value       = azurerm_linux_virtual_machine.vm.id
}

# Devuelve la dirección IP privada de la VM
output "vm_public_ip" {
  description = "La dirección IP privada de la VM"
  value       = azurerm_network_interface.nic.private_ip_address
}

# Devuelve la dirección IP publica de la VM
output "vm_public_ip" {
  description = "Public IP of the Virtual Machine"
  value       = azurerm_public_ip.vm_public_ip.ip_address
}