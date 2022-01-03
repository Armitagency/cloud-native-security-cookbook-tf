data "azurerm_management_group" "root" {
  name = var.root_management_group_uuid
}

resource "azurerm_policy_assignment" "key_vault_sentinel" {
  name                 = "key_vault_sentinel"
  location             = azurerm_resource_group.sentinel.location
  scope                = data.azurerm_management_group.root.id
  policy_definition_id = join("", [
    "/providers/Microsoft.Authorization/policyDefinitions/",
    "951af2fa-529b-416e-ab6e-066fd85ac459"
  ])

  identity {
    type = "SystemAssigned"
  }

  parameters = <<PARAMETERS
{
  "logAnalytics": {
    "value": "${azurerm_log_analytics_workspace.sentinel.name}"
  }
}
PARAMETERS

}

data "azurerm_sentinel_alert_rule_template" "sensitive_key_vault" {
  log_analytics_workspace_id = azurerm_log_analytics_workspace.sentinel.id
  display_name               = "Sensitive Azure Key Vault operations"
}

locals {
  key_vault = data.azurerm_sentinel_alert_rule_template.sensitive_key_vault
}

resource "azurerm_sentinel_alert_rule_scheduled" "sensitive_key_vault" {
  name                       = "sensitive_key_vault"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.sentinel.id
  display_name               = local.key_vault.display_name
  severity                   = local.key_vault.scheduled_template[0].severity
  query                      = local.key_vault.scheduled_template[0].query
}
