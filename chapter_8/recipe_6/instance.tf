resource "azurerm_linux_virtual_machine" "inventory" {
  name                = "inventory-example"
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  custom_data         = base64encode(local.custom_data)
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
    sku       = "18.04-LTS"
    version   = "latest"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_virtual_machine_extension" "example" {
  name                 = "OmsAgentForLinux"
  virtual_machine_id   = azurerm_linux_virtual_machine.inventory.id
  publisher            = "Microsoft.EnterpriseCloud.Monitoring"
  type                 = "OmsAgentForLinux"
  type_handler_version = "1.13"

  settings = <<SETTINGS
{
    "workspaceId": "${azurerm_log_analytics_workspace.inventory.workspace_id}"
}
SETTINGS

  protected_settings = <<SETTINGS
{
    "workspaceKey": "${azurerm_log_analytics_workspace.inventory.primary_shared_key}"
}
SETTINGS
}

resource "azurerm_network_interface" "inventory" {
  name                = "inventory"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.instance.id
  }
}

resource "azurerm_public_ip" "instance" {
  name                = "inventory"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  allocation_method   = "Static"
  sku                 = "Standard"
  availability_zone   = "1"
}

resource "azurerm_virtual_network" "this" {
  name                = "this"
  address_space       = ["10.0.0.0/24"]
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
}

resource "azurerm_subnet" "public" {
  name                 = "public"
  resource_group_name  = azurerm_resource_group.management.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.0.0/24"]
}
