data "azurerm_subscription" "current" {}

resource "azurerm_subscription_policy_assignment" "vm_backups" {
  name                 = "vm_backups"
  location             = azurerm_resource_group.backups.location
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = join("", [
    "/providers/Microsoft.Authorization/policyDefinitions/",
    "013e242c-8828-4970-87b3-ab247555486d"
  ])
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_resource_group_policy_assignment" "default_vm_backups" {
  name                 = "default_vm_backups"
  location             = azurerm_resource_group.backups.location
  resource_group_id    = azurerm_resource_group.backups.id
  policy_definition_id = join("", [
    "/providers/Microsoft.Authorization/policyDefinitions/",
    "09ce66bc-1220-4153-8104-e3f51c936913"
  ])

  parameters = <<PARAMETERS
{
  "vaultLocation": {
    "value": "${azurerm_resource_group.backups.location}"
  },
  "backupPolicyId": {
    "value": "${azurerm_backup_policy_vm.daily.id}"
  }
}
PARAMETERS

  identity {
    type = "SystemAssigned"
  }
}
