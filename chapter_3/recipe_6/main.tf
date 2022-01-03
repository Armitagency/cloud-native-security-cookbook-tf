data "azurerm_subscriptions" "available" {}

locals {
  log_categories = toset([
    "Administrative",
    "Security",
    "ServiceHealth",
    "Alert",
    "Recommendation",
    "Policy",
    "Autoscale",
    "ResourceHealth"
  ])
}

resource "azurerm_resource_group" "activity-log-archive" {
  name     = "activity-log-archive"
  location = var.location
}

resource "azurerm_storage_account" "activity-logs" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.activity-log-archive.name
  location                 = azurerm_resource_group.activity-log-archive.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

resource "azurerm_storage_container" "activity-logs" {
  name                  = "activity-logs"
  storage_account_name  = azurerm_storage_account.activity-logs.name
  container_access_type = "private"
}

resource "azurerm_log_analytics_workspace" "activity-logs" {
  name                = "activity-logs"
  location            = azurerm_resource_group.activity-log-archive.location
  resource_group_name = azurerm_resource_group.activity-log-archive.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "activity-to-storage" {
  for_each                   = {
    for subscription in data.azurerm_subscriptions.available.subscriptions :
    subscription.subscription_id => subscription
  }
  name                       = "activity-${each.value.subscription_id}"
  target_resource_id         = each.value.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.activity-logs.id
  storage_account_id         = azurerm_storage_account.activity-logs.id

  dynamic "log" {
    for_each = local.log_categories
    content {
      category = log.value
    }
  }
}
