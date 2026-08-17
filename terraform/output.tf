output "vm_public_ip" {
  value = azurerm_public_ip.alams-ip.ip_address

}

output "azurerm_linux_virtual_machine_name" {
  value = azurerm_linux_virtual_machine.alams-vm.name
}

output "ssh_ouput_connect_command" {
  value = "ssh ${azurerm_linux_virtual_machine.alams-vm.admin_username}@${azurerm_public_ip.alams-ip.ip_address}"


}

