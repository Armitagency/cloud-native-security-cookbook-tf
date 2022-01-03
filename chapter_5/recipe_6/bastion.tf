resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.bastion_cidr]
}

resource "azurerm_public_ip" "bastion" {
  name                = "bastion"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "this" {
  name                = "this"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }
}

resource "azurerm_application_security_group" "s" {
  name                = "ssh_example"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_network_security_rule" "bastion_ingress" {
  name                         = "bastion-private-ingress"
  priority                     = 100
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "22"
  source_address_prefixes      = azurerm_subnet.bastion.address_prefixes
  destination_application_security_group_ids = [
    azurerm_application_security_group.ssh_example.id
  ]
  resource_group_name          = azurerm_resource_group.network.name
  network_security_group_name  = azurerm_network_security_group.private.name
}
