resource "azurerm_resource_group" "sentinel" {
  name     = "sentinel"
  location = var.location
}

resource "azurerm_log_analytics_workspace" "sentinel" {
  name                = "sentinel"
  location            = azurerm_resource_group.sentinel.location
  resource_group_name = azurerm_resource_group.sentinel.name
  sku                 = "PerGB2018"
}

resource "azurerm_log_analytics_solution" "sentinel" {
  solution_name         = "SecurityInsights"
  location              = azurerm_resource_group.sentinel.location
  resource_group_name   = azurerm_resource_group.sentinel.name
  workspace_resource_id = azurerm_log_analytics_workspace.sentinel.id
  workspace_name        = azurerm_log_analytics_workspace.sentinel.name
  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/SecurityInsights"
  }
}

resource "azurerm_sentinel_data_connector_azure_security_center" "this" {
  name                       = "security_center"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.sentinel.id
}

resource "azurerm_sentinel_data_connector_threat_intelligence" "this" {
  name                       = "threat_intelligence"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.sentinel.id
}
