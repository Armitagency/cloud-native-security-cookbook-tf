resource "azurerm_linux_virtual_machine" "inventory" {
  name                = "inventory-example"
  resource_group_name = azurerm_resource_group.backups.name
  location            = azurerm_resource_group.backups.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.inventory.id,
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

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_network_interface" "inventory" {
  name                = "inventory"
  location            = azurerm_resource_group.backups.location
  resource_group_name = azurerm_resource_group.backups.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.instance.id
  }
}

resource "azurerm_public_ip" "instance" {
  name                = "inventory"
  location            = azurerm_resource_group.backups.location
  resource_group_name = azurerm_resource_group.backups.name
  allocation_method   = "Static"
  sku                 = "Standard"
  availability_zone   = "1"
}

resource "azurerm_virtual_network" "this" {
  name                = "this"
  address_space       = ["10.0.0.0/24"]
  location            = azurerm_resource_group.backups.location
  resource_group_name = azurerm_resource_group.backups.name
}

resource "azurerm_subnet" "public" {
  name                 = "public"
  resource_group_name  = azurerm_resource_group.backups.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.0.0/24"]
}
