resource "azurerm_resource_group" "network" {
  name     = "network"
  location = var.location
}

resource "azurerm_public_ip" "nat_gateway" {
  name                = "nat-gateway"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  allocation_method   = "Static"
  sku                 = "Standard"
  availability_zone   = "1"
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat_gateway.id
}

resource "azurerm_nat_gateway" "this" {
  name                    = "this"
  location                = azurerm_resource_group.network.location
  resource_group_name     = azurerm_resource_group.network.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_virtual_network" "this" {
  name                = "this"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_subnet" "public" {
  name                 = "public"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.public_cidr]
}

resource "azurerm_subnet" "private" {
  name                                           = "private"
  resource_group_name                            = azurerm_resource_group.network.name
  virtual_network_name                           = azurerm_virtual_network.this.name
  enforce_private_link_endpoint_network_policies = true
  enforce_private_link_service_network_policies  = true
  address_prefixes                               = [var.private_cidr]
}

resource "azurerm_network_security_rule" "public_default_ingress" {
  name                        = "private_default_ingress"
  priority                    = 4096
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.network.name
  network_security_group_name = azurerm_network_security_group.public.name
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  subnet_id      = azurerm_subnet.private.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.internal_cidr]
}

resource "azurerm_route_table" "default" {
  name                = "default"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_route" "local" {
  name                = "local"
  resource_group_name = azurerm_resource_group.network.name
  route_table_name    = azurerm_route_table.default.name
  address_prefix      = var.vnet_cidr
  next_hop_type       = "VnetLocal"
}

resource "azurerm_route" "internet" {
  name                   = "internet"
  resource_group_name    = azurerm_resource_group.network.name
  route_table_name       = azurerm_route_table.default.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_firewall.this.ip_configuration[0].private_ip_address
}

resource "azurerm_subnet_route_table_association" "public" {
  subnet_id      = azurerm_subnet.public.id
  route_table_id = azurerm_route_table.default.id
}

resource "azurerm_subnet_route_table_association" "private" {
  subnet_id      = azurerm_subnet.private.id
  route_table_id = azurerm_route_table.default.id
}

resource "azurerm_route_table" "internal" {
  name                = "internal"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_route" "internal_local" {
  name                = "internal_local"
  resource_group_name = azurerm_resource_group.network.name
  route_table_name    = azurerm_route_table.internal.name
  address_prefix      = var.vnet_cidr
  next_hop_type       = "VnetLocal"
}

resource "azurerm_route" "internal_internet" {
  name                = "internal_internet"
  resource_group_name = azurerm_resource_group.network.name
  route_table_name    = azurerm_route_table.internal.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "None"
}

resource "azurerm_subnet_route_table_association" "internal" {
  subnet_id      = azurerm_subnet.internal.id
  route_table_id = azurerm_route_table.internal.id
}

resource "azurerm_network_ddos_protection_plan" "this" {
  name                = "this"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.network.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.firewall_cidr]
}

resource "azurerm_public_ip" "firewall" {
  name                = "firewall"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "this" {
  name                = "this"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall.id
  }
}

resource "azurerm_network_security_group" "public" {
  name                = "public"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_network_security_group" "private" {
  name                = "private"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
}

resource "azurerm_network_security_group" "internal" {
  name                = "internal"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_subnet_network_security_group_association" "internal" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.internal.id
}
