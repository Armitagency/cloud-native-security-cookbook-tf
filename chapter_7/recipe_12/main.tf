data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "remediation" {
  name     = "remediation"
  location = var.location
}

resource "azurerm_eventgrid_system_topic" "policy_state_changes" {
  name                   = "PolicyStateChanges"
  resource_group_name    = azurerm_resource_group.remediation.name
  location               = "global"
  source_arm_resource_id = data.azurerm_subscription.current.id
  topic_type             = "Microsoft.PolicyInsights.PolicyStates"
}

resource "azurerm_eventgrid_system_topic_event_subscription" "remediation" {
  name                = "policy-state-changes-alerting"
  system_topic        = azurerm_eventgrid_system_topic.policy_state_changes.name
  resource_group_name = azurerm_resource_group.remediation.name

  azure_function_endpoint {
    function_id = join("/", [
      azurerm_function_app.remediation.id,
      "functions",
      "Remediation"
    ])
    max_events_per_batch              = 1
    preferred_batch_size_in_kilobytes = 64
  }

  depends_on = [
    null_resource.deploy
  ]
}

resource "random_string" "storage_account" {
  length  = 16
  special = false
  upper = false
}

resource "azurerm_storage_account" "r" {
  name                     = random_string.storage_account.result
  resource_group_name      = azurerm_resource_group.remediation.name
  location                 = azurerm_resource_group.remediation.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "remediation" {
  name                = "remediation"
  location            = azurerm_resource_group.remediation.location
  resource_group_name = azurerm_resource_group.remediation.name
  kind                = "functionapp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "random_string" "functionapp" {
  length  = 16
  special = false
  upper = false
}

resource "azurerm_storage_account" "r" {
  name                       = random_string.functionapp.result
  location                   = azurerm_resource_group.remediation.location
  resource_group_name        = azurerm_resource_group.remediation.name
  app_service_plan_id        = azurerm_app_service_plan.remediation.id
  storage_account_name       = azurerm_storage.r.name
  storage_account_access_key = azurerm_storage.r.primary_access_key
  os_type                    = "linux"
  version                    = "~3"

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
  }

  site_config {
    linux_fx_version = "Python|3.9"
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "null_resource" "deploy" {
  provisioner "local-exec" {
    command = join(" ", [
      "func azure functionapp publish",
      azurerm_function_app.remediation.name
    ])
  }

  depends_on = [
    azurerm_function_app.remediation
  ]
}

resource "azurerm_role_assignment" "remediation" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = azurerm_role_definition.remediation.name
  principal_id         = azurerm_function_app.remediation.identity.0.principal_id
}

resource "azurerm_role_definition" "remediation" {
  name        = "automated-remediation"
  scope       = data.azurerm_subscription.current.id

  permissions {
    actions     = ["Microsoft.PolicyInsights/remediations/write"]
    not_actions = []
  }

  assignable_scopes = [
    data.azurerm_subscription.current.id
  ]
}
