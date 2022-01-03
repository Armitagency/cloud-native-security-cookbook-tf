resource "azurerm_network_interface_application_security_group_association" "s" {
  network_interface_id          = azurerm_network_interface.ssh_example.id
  application_security_group_id = azurerm_application_security_group.s.id
}

resource "azurerm_linux_virtual_machine" "ssh_example" {
  name                = "ssh-example"
  resource_group_name = azurerm_resource_group.network.name
  location            = azurerm_resource_group.network.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.ssh_example.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_network_interface" "ssh_example" {
  name                = "ssh_example"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.private.id
    private_ip_address_allocation = "Dynamic"
  }
}
