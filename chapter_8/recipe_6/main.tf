resource "azurerm_resource_group" "management" {
  name     = "instance-management"
  location = var.location
}

resource "azurerm_automation_account" "this" {
  name                = "instance-management"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name

  sku_name = "Basic"
}

resource "azurerm_log_analytics_workspace" "inventory" {
  name                = "inventory"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_log_analytics_linked_service" "law_link" {
  resource_group_name = azurerm_resource_group.management.name
  workspace_id        = azurerm_log_analytics_workspace.inventory.id
  read_access_id      = azurerm_automation_account.this.id
}

resource "azurerm_log_analytics_solution" "law_solution_updates" {
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location

  solution_name         = "Updates"
  workspace_resource_id = azurerm_log_analytics_workspace.inventory.id
  workspace_name        = azurerm_log_analytics_workspace.inventory.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/Updates"
  }
}

resource "azurerm_log_analytics_solution" "law_solution_change_tracking" {
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location

  solution_name         = "ChangeTracking"
  workspace_resource_id = azurerm_log_analytics_workspace.inventory.id
  workspace_name        = azurerm_log_analytics_workspace.inventory.name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ChangeTracking"
  }
}
