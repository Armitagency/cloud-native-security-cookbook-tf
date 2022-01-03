resource "azurerm_resource_group" "cal" {
  provider = azurerm.central
  name     = "centralized-application-logs"
  location = var.location
}

resource "azurerm_log_analytics_workspace" "application-logs" {
  provider            = azurerm.central
  name                = "application-logs"
  location            = azurerm_resource_group.cal.location
  resource_group_name = azurerm_resource_group.cal.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_resource_group" "delivery" {
  provider = azurerm.delivery
  name     = "delivery-rg"
  location = var.location
}

resource "azurerm_app_service_plan" "delivery" {
  provider            = azurerm.delivery
  name                = "delivery-service-plan"
  location            = azurerm_resource_group.delivery.location
  resource_group_name = azurerm_resource_group.delivery.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "delivery" {
  provider = azurerm.delivery
  name     = "delivery-${var.delivery_subscription_id}"

  site_config {
    linux_fx_version = "DOCKER|appsvcsample/static-site:latest"
    always_on        = true
  }

  location            = azurerm_resource_group.delivery.location
  resource_group_name = azurerm_resource_group.delivery.name
  app_service_plan_id = azurerm_app_service_plan.delivery.id
}

data "azurerm_monitor_diagnostic_categories" "delivery_app_service" {
  provider    = azurerm.delivery
  resource_id = azurerm_app_service.delivery.id
}

resource "azurerm_monitor_diagnostic_setting" "delivery_central_log_forwarding" {
  provider                   = azurerm.delivery
  name                       = "central_log_forwarding"
  target_resource_id         = azurerm_app_service.delivery.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.application-logs.id

  dynamic "log" {
    for_each = data.azurerm_monitor_diagnostic_categories.delivery_app_service.logs
    content {
      category = log.value
      enabled  = true

      retention_policy {
        days    = 0
        enabled = false
      }
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }
}
