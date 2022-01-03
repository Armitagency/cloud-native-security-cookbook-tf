locals {
  function = azurerm_application_insights.function
}

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "function" {
  name     = var.function_name
  location = var.location
}

resource "random_string" "sa_name" {
  length  = 16
  number = false
}

resource "azurerm_storage_account" "f" {
  name                     = random_string.sa_name.result
  resource_group_name      = azurerm_resource_group.function.name
  location                 = azurerm_resource_group.function.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "function" {
  name                = var.function_name
  location            = azurerm_resource_group.function.location
  resource_group_name = azurerm_resource_group.function.name
  kind                = "functionapp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "function" {
  name                       = var.function_name
  location                   = azurerm_resource_group.function.location
  resource_group_name        = azurerm_resource_group.function.name
  app_service_plan_id        = azurerm_app_service_plan.function.id
  storage_account_name       = azurerm_storage_account.f.name
  storage_account_access_key = azurerm_storage_account.f.primary_access_key
  os_type                    = "linux"
  version                    = "~3"

  app_settings = {
    APPINSIGHTS_INSTRUMENTATIONKEY = local.function.instrumentation_key
    APPLICATIONINSIGHTS_CONNECTION_STRING = local.function.connection_string
    FUNCTIONS_WORKER_RUNTIME       = "python"
  }

  site_config {
    linux_fx_version = "PYTHON|3.9"
  }

  identity {
    type = "SystemAssigned"
  }
}

data "archive_file" "code" {
  type        = "zip"
  source_dir  = "${path.module}/${var.function_name}"
  output_path = "${path.module}/main.zip"
}

resource "null_resource" "deploy" {
  triggers = {
    checksum = filebase64sha256(
      data.archive_file.code.output_path
    )
  }
  provisioner "local-exec" {
    command = "func azure functionapp publish ${var.function_name}"
  }

  depends_on = [
    azurerm_function_app.function
  ]
}

resource "azurerm_application_insights" "function" {
  name                = var.function_name
  location            = azurerm_resource_group.function.location
  resource_group_name = azurerm_resource_group.function.name
  workspace_id        = azurerm_log_analytics_workspace.insights.id
  application_type    = "other"
}

resource "azurerm_log_analytics_workspace" "insights" {
  name                = var.function_name
  location            = azurerm_resource_group.function.location
  resource_group_name = azurerm_resource_group.function.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_metric_alert" "exceptions" {
  name                = "exceptions"
  resource_group_name = azurerm_resource_group.function.name
  scopes = [
    azurerm_application_insights.function.id
  ]

  criteria {
    metric_namespace = "Microsoft.Insights/components"
    metric_name      = "exceptions/count"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.email.id
  }
}

resource "azurerm_monitor_action_group" "email" {
  name                = var.function_name
  resource_group_name = azurerm_resource_group.function.name
  short_name          = var.function_name

  email_receiver {
    name          = "ops"
    email_address = var.email
  }
}
