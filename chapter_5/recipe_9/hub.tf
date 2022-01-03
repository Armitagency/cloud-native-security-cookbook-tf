resource "azurerm_resource_group" "hub" {
  provider = azurerm.hub
  name     = "hub"
  location = var.location
}

resource "azurerm_virtual_wan" "this" {
  provider            = azurerm.hub
  name                = "this"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
}

resource "azurerm_virtual_hub" "this" {
  provider            = azurerm.hub
  name                = "this"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  virtual_wan_id      = azurerm_virtual_wan.this.id
  sku                 = "Standard"
  address_prefix      = var.hub_cidr
}

resource "azurerm_virtual_hub_connection" "spoke" {
  provider                  = azurerm.hub
  name                      = "spoke"
  virtual_hub_id            = azurerm_virtual_hub.this.id
  remote_virtual_network_id = azurerm_virtual_network.this.id
}

resource "azurerm_express_route_gateway" "this" {
  name                = "this"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  virtual_hub_id      = azurerm_virtual_hub.this.id
  scale_units         = 1
}

resource "azurerm_firewall" "hub" {
  name                = "hub"
  resource_group_name = azurerm_resource_group.hub.name
  location            = azurerm_resource_group.hub.location
  sku_name            = "AZFW_Hub"
  threat_intel_mode   = ""

  virtual_hub {
    virtual_hub_id  = azurerm_virtual_hub.this.id
    public_ip_count = 1
  }
}
