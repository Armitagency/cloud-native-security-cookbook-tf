resource "azurerm_virtual_network" "isolated" {
  name                = "isolated"
  address_space       = ["10.2.0.0/24"]
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_virtual_network" "shared" {
  name                = "shared"
  address_space       = ["10.3.0.0/24"]
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_virtual_hub_route_table" "isolation" {
  provider       = azurerm.hub
  name           = "isolation"
  virtual_hub_id = azurerm_virtual_hub.this.id
}

resource "azurerm_virtual_hub_route_table" "shared" {
  provider       = azurerm.hub
  name           = "shared"
  virtual_hub_id = azurerm_virtual_hub.this.id
}

resource "azurerm_virtual_hub_connection" "isolated" {
  provider                  = azurerm.hub
  name                      = "isolated"
  virtual_hub_id            = azurerm_virtual_hub.this.id
  remote_virtual_network_id = azurerm_virtual_network.isolated.id

  routing {
    associated_route_table_id = azurerm_virtual_hub_route_table.isolation.id

    propagated_route_table {
      route_table_ids = [
        azurerm_virtual_hub_route_table.shared.id
      ]
    }
  }
}

resource "azurerm_virtual_hub_connection" "shared" {
  provider                  = azurerm.hub
  name                      = "shared"
  virtual_hub_id            = azurerm_virtual_hub.this.id
  remote_virtual_network_id = azurerm_virtual_network.shared.id

  routing {
    associated_route_table_id = azurerm_virtual_hub_route_table.shared.id

    propagated_route_table {
      route_table_ids = [
        azurerm_virtual_hub_route_table.isolation.id,
        azurerm_virtual_hub_route_table.shared.id
      ]
    }
  }
}

// resource "azurerm_express_route_connection" "this" {
//   name                             = "this"
//   express_route_gateway_id         = azurerm_express_route_gateway.this.id
//   express_route_circuit_peering_id = azurerm_express_route_circuit_peering.this.id

//   routing {
//     associated_route_table_id = azurerm_virtual_hub_route_table.shared.id

//     propagated_route_table {
//       route_table_ids = [
//         azurerm_virtual_hub_route_table.isolation.id,
//         azurerm_virtual_hub_route_table.shared.id
//       ]
//     }
//   }
// }
