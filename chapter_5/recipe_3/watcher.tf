resource "azurerm_resource_group" "watcher" {
  name     = "watcher"
  location = var.location
}

resource "azurerm_network_watcher" "this" {
  name                = "this"
  location            = azurerm_resource_group.watcher.location
  resource_group_name = azurerm_resource_group.watcher.name
}

resource "azurerm_storage_account" "watcher" {
  name                = ""
  resource_group_name = azurerm_resource_group.watcher.name
  location            = azurerm_resource_group.watcher.location

  account_tier              = "Standard"
  account_kind              = "StorageV2"
  account_replication_type  = "LRS"
  enable_https_traffic_only = true
}

resource "azurerm_log_analytics_workspace" "watcher" {
  name                = "watcher"
  location            = azurerm_resource_group.watcher.location
  resource_group_name = azurerm_resource_group.watcher.name
  sku                 = "PerGB2018"
}

resource "azurerm_network_watcher_flow_log" "this" {
  for_each = toset([
    azurerm_network_security_group.public.id,
    azurerm_network_security_group.private.id,
    azurerm_network_security_group.internal.id,
  ])

  network_watcher_name = azurerm_network_watcher.this.name
  resource_group_name  = azurerm_resource_group.watcher.name

  network_security_group_id = each.value
  storage_account_id        = azurerm_storage_account.watcher.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = 7
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.watcher.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.watcher.location
    workspace_resource_id = azurerm_log_analytics_workspace.watcher.id
  }
}
