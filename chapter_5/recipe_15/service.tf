resource "azurerm_resource_group" "s" {
  name     = "service"
  location = var.location
}

resource "azurerm_virtual_network" "s" {
  name                = "service"
  resource_group_name = azurerm_resource_group.s.name
  location            = azurerm_resource_group.s.location
  address_space       = [var.service_cidr]
}

resource "azurerm_subnet" "service" {
  name                                           = "service"
  resource_group_name                            = azurerm_resource_group.s.name
  virtual_network_name                           = azurerm_virtual_network.s.name
  address_prefixes                               = [var.service_cidr]
  enforce_private_link_service_network_policies  = true
  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_lb" "service" {
  name                = "service"
  sku                 = "Standard"
  location            = azurerm_resource_group.s.location
  resource_group_name = azurerm_resource_group.s.name

  frontend_ip_configuration {
    name      = "frontend"
    subnet_id = azurerm_subnet.service.id
  }
}

resource "azurerm_private_link_service" "service" {
  name                = "service"
  resource_group_name = azurerm_resource_group.s.name
  location            = azurerm_resource_group.s.location

  load_balancer_frontend_ip_configuration_ids = [
    azurerm_lb.service.frontend_ip_configuration.0.id
  ]

  nat_ip_configuration {
    name      = "primary"
    subnet_id = azurerm_subnet.service.id
    primary   = true
  }
}
