data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "compliance_alerting" {
  name     = "compliance_alerting"
  location = var.location
}

resource "azurerm_eventgrid_system_topic" "policy_state_changes" {
  name                   = "PolicyStateChanges"
  resource_group_name    = azurerm_resource_group.compliance_alerting.name
  location               = "global"
  source_arm_resource_id = data.azurerm_subscription.current.id
  topic_type             = "Microsoft.PolicyInsights.PolicyStates"
}

resource "azurerm_eventgrid_system_topic_event_subscription" "alerting" {
  name                = "policy-state-changes-alerting"
  system_topic        = azurerm_eventgrid_system_topic.policy_state_changes.name
  resource_group_name = azurerm_resource_group.compliance_alerting.name

  azure_function_endpoint {
    function_id = join("/", [
      azurerm_function_app.compliance_alerting.id,
      "functions",
      "ComplianceAlerting"
    ])
    max_events_per_batch              = 1
    preferred_batch_size_in_kilobytes = 64
  }

  depends_on = [
    null_resource.deploy
  ]
}

resource "azurerm_storage_account" "compliance_alerting" {
  name                     = "compliancealerting"
  resource_group_name      = azurerm_resource_group.compliance_alerting.name
  location                 = azurerm_resource_group.compliance_alerting.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "compliance_alerting" {
  name                = "compliancealerting"
  location            = azurerm_resource_group.compliance_alerting.location
  resource_group_name = azurerm_resource_group.compliance_alerting.name
  kind                = "functionapp"
  reserved            = true

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "compliance_alerting" {
  name                       = "compliancealerting"
  location                   = azurerm_resource_group.compliance_alerting.location
  resource_group_name        = azurerm_resource_group.compliance_alerting.name
  app_service_plan_id        = azurerm_app_service_plan.compliance_alerting.id
  storage_account_name       = azurerm_storage_account.compliance_alerting.name
  storage_account_access_key = azurerm_storage_account.compliance_alerting.primary_access_key
  os_type                    = "linux"
  version                    = "~3"

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "python"
    KEY_VAULT_URI            = azurerm_key_vault.slack.vault_uri
    CHANNEL                  = var.channel
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
    command = "func azure functionapp publish compliancealerting"
  }

  depends_on = [
    azurerm_function_app.compliance_alerting
  ]
}

resource "random_string" "key_vault" {
  length  = 16
  special = false
}

resource "azurerm_key_vault" "slack" {
  name                      = random_string.key_vault.result
  location                  = azurerm_resource_group.compliance_alerting.location
  resource_group_name       = azurerm_resource_group.compliance_alerting.name
  enable_rbac_authorization = true

  sku_name  = "standard"
  tenant_id = data.azurerm_client_config.current.tenant_id
}

resource "azurerm_role_assignment" "secret_officer" {
  scope                = azurerm_key_vault.slack.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "token" {
  name         = "token"
  value        = "mytoken"
  key_vault_id = azurerm_key_vault.slack.id

  depends_on = [
    azurerm_role_assignment.secret_officer
  ]
}

resource "azurerm_role_assignment" "secret_access" {
  scope                = azurerm_key_vault.slack.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_function_app.compliance_alerting.identity.0.principal_id
}

output "update_secret_command" {
  value = join(" ", [
    "az keyvault secret set -n token --vault-name",
    azurerm_key_vault.slack.name,
    "--value"
  ])
}
