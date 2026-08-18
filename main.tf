terraform {
  backend "azurerm" {
    resource_group_name  = "alams-tfstate"
    storage_account_name = "alams404"
    container_name       = "mytfstate"
    key                  = "alamsvm.tfstate"
    use_azuread_auth     = true
  }
}


# resouce-gruop
resource "azurerm_resource_group" "alams-project" {
  name     = "alams-project"
  location = "southafricanorth"
}
# virtual-network
resource "azurerm_virtual_network" "vnet" {
  name                = "alams-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.alams-project.location
  resource_group_name = azurerm_resource_group.alams-project.name
}
# subnet
resource "azurerm_subnet" "alams-subnet" {
  name                 = "alams-subnet"
  resource_group_name  = azurerm_resource_group.alams-project.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# public-ip
resource "azurerm_public_ip" "alams-ip" {
  name                = "alams-ip"
  resource_group_name = azurerm_resource_group.alams-project.name
  location            = azurerm_resource_group.alams-project.location
  allocation_method   = "Static"

  tags = {
    environment = "production"
  }
}

# NSG
resource "azurerm_network_security_group" "alams-nsg" {
  name                = "alams-nsg"
  location            = azurerm_resource_group.alams-project.location
  resource_group_name = azurerm_resource_group.alams-project.name
}

# NSG rule (allow http port 80)
resource "azurerm_network_security_rule" "allow-port-80" {
  name                        = "allow-port-80"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.alams-project.name
  network_security_group_name = azurerm_network_security_group.alams-nsg.name
}

# NSG RULE (allow ssh port 22)
resource "azurerm_network_security_rule" "allow-port-22" {
  name                        = "allow-port-22"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.alams-project.name
  network_security_group_name = azurerm_network_security_group.alams-nsg.name
}

# network interface
resource "azurerm_network_interface" "alams-nic" {
  name                = "alams-nic-aso"
  location            = azurerm_resource_group.alams-project.location
  resource_group_name = azurerm_resource_group.alams-project.name

  ip_configuration {
    name                          = "private-ip"
    subnet_id                     = azurerm_subnet.alams-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.alams-ip.id
  }
}

# NIC NSG ASSOCIATIOM
resource "azurerm_network_interface_security_group_association" "alams-nic-nsg-association" {
  network_interface_id      = azurerm_network_interface.alams-nic.id
  network_security_group_id = azurerm_network_security_group.alams-nsg.id
}



# virtual-machine
resource "azurerm_linux_virtual_machine" "alams-vm" {
  name                  = "alams-vm"
  resource_group_name   = azurerm_resource_group.alams-project.name
  location              = azurerm_resource_group.alams-project.location
  size                  = "Standard_B1s"
  admin_username        = "alams404"
  network_interface_ids = [azurerm_network_interface.alams-nic.id]

  admin_ssh_key {
    username   = "alams404"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"

  }

  source_image_reference {
    publisher = "canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"

  }

}

