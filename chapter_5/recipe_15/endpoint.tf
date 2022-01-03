resource "azurerm_private_endpoint" "service" {
  name                = "service"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  subnet_id           = azurerm_subnet.private.id

  private_service_connection {
    name                           = "service"
    private_connection_resource_id = azurerm_private_link_service.service.id
    is_manual_connection           = false
  }
}

resource "azurerm_network_security_rule" "endpoint_egress" {
  name                         = "endpoint-egress"
  priority                     = 101
  direction                    = "Outbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "80"
  source_application_security_group_ids = [
    azurerm_application_security_group.application.id
  ]
  destination_address_prefixes = [
    azurerm_private_endpoint.service.private_service_connection[0].private_ip_address
  ]
  resource_group_name          = azurerm_resource_group.network.name
  network_security_group_name  = azurerm_network_security_group.private.name
}

resource "azurerm_network_security_rule" "endpoint_ingress" {
  name                         = "endpoint-ingress"
  priority                     = 101
  direction                    = "Inbound"
  access                       = "Allow"
  protocol                     = "Tcp"
  source_port_range            = "*"
  destination_port_range       = "80"
  source_application_security_group_ids = [
    azurerm_application_security_group.application.id
  ]
  destination_address_prefixes = [
    azurerm_private_endpoint.service.private_service_connection[0].private_ip_address
  ]
  resource_group_name          = azurerm_resource_group.network.name
  network_security_group_name  = azurerm_network_security_group.private.name
}
