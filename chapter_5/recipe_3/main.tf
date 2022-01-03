locals {
  fw    = azurerm_firewall.this[0]
  fw_ip = local.fw.ip_configuration[0].private_ip_address
}

resource "azurerm_resource_group" "n" {
  name     = "network"
  location = var.location
}

resource "azurerm_public_ip" "nat_gateway" {
  name                = "nat-gateway"
  location            = azurerm_resource_group.n.location
  resource_group_name = azurerm_resource_group.n.name
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
  location                = azurerm_resource_group.n.location
  resource_group_name     = azurerm_resource_group.n.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_virtual_network" "n" {
  name                = "this"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.n.location
  resource_group_name = azurerm_resource_group.n.name
}

resource "azurerm_subnet" "public" {
  name                 = "public"
  resource_group_name  = azurerm_resource_group.n.name
  virtual_network_name = azurerm_virtual_network.n.name
  address_prefixes     = [var.public_cidr]
}
resource "azurerm_subnet" "private" {
  name                 = "private"
  resource_group_name  = azurerm_resource_group.n.name
  virtual_network_name = azurerm_virtual_network.n.name
  address_prefixes     = [var.private_cidr]
}

resource "azurerm_subnet_nat_gateway_association" "private" {
  subnet_id      = azurerm_subnet.private.id
  nat_gateway_id = azurerm_nat_gateway.this.id
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.n.name
  virtual_network_name = azurerm_virtual_network.n.name
  address_prefixes     = [var.internal_cidr]
}

resource "azurerm_route_table" "this" {
  name                = "this"
  location            = azurerm_resource_group.n.location
  resource_group_name = azurerm_resource_group.n.name
}

resource "azurerm_route" "local" {
  name                = "local"
  resource_group_name = azurerm_resource_group.n.name
  route_table_name    = azurerm_route_table.this.name
  address_prefix      = var.vnet_cidr
  next_hop_type       = "VnetLocal"
}

resource "azurerm_route" "internet_via_firewall" {
  count                  = var.enable_firewall ? 1 : 0
  name                   = "internet"
  resource_group_name    = azurerm_resource_group.n.name
  route_table_name       = azurerm_route_table.this.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = local.fw_ip
}

resource "azurerm_route" "internet_via_nat" {
  count               = var.enable_firewall ? 0 : 1
  name                = "internet"
  resource_group_name = azurerm_resource_group.n.name
  route_table_name    = azurerm_route_table.this.name
  address_prefix      = "0.0.0.0/0"
  next_hop_type       = "VirtualNetworkGateway"
}

resource "azurerm_network_ddos_protection_plan" "this" {
  count               = var.enable_ddos_protection ? 1 : 0
  name                = "this"
  location            = azurerm_resource_group.n.location
  resource_group_name = azurerm_resource_group.n.name
}

resource "azurerm_subnet" "firewall" {
  count                = var.enable_firewall ? 1 : 0
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.n.name
  virtual_network_name = azurerm_virtual_network.n.name
  address_prefixes     = [var.firewall_cidr]
}

resource "azurerm_public_ip" "firewall" {
  count               = var.enable_firewall ? 1 : 0
  name                = "firewall"
  location            = azurerm_resource_group.n.location
  resource_group_name = azurerm_resource_group.n.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "this" {
  count               = var.enable_firewall ? 1 : 0
  name                = "this"
  location            = azurerm_resource_group.n.location
  resource_group_name = azurerm_resource_group.n.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall[0].id
    public_ip_address_id = azurerm_public_ip.firewall[0].id
  }
}

resource "azurerm_network_security_group" "public" {
  name                = "public"
  location            = azurerm_resource_group.n.location
  resource_group_name = azurerm_resource_group.n.name
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_network_security_group" "private" {
  name                = "private"
  location            = azurerm_resource_group.n.location
  resource_group_name = azurerm_resource_group.n.name
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
}

resource "azurerm_network_security_group" "internal" {
  name                = "internal"
  location            = azurerm_resource_group.n.location
  resource_group_name = azurerm_resource_group.n.name
}

resource "azurerm_subnet_network_security_group_association" "internal" {
  subnet_id                 = azurerm_subnet.internal.id
  network_security_group_id = azurerm_network_security_group.internal.id
}
