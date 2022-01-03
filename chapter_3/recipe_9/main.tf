data "azurerm_management_group" "target" {
  name = var.target_management_group_uuid
}

data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "security_center" {
  name     = "security-center"
  location = var.location
}

resource "azurerm_log_analytics_workspace" "security_center" {
  name                = "security-center"
  location            = azurerm_resource_group.security_center.location
  resource_group_name = azurerm_resource_group.security_center.name
  sku                 = "PerGB2018"
}

resource "azurerm_security_center_workspace" "security_center" {
  scope        = data.azurerm_subscription.current.id
  workspace_id = azurerm_log_analytics_workspace.security_center.id
}

resource "azurerm_security_center_auto_provisioning" "this" {
  auto_provision = "On"
}

locals {
  resource_types = toset([
    "AppServices",
    "ContainerRegistry",
    "KeyVaults",
    "KubernetesService",
    "SqlServers",
    "SqlServerVirtualMachines",
    "StorageAccounts",
    "VirtualMachines",
    "Arm",
    "Dns"
  ])
}

resource "azurerm_security_center_subscription_pricing" "this" {
  for_each      = local.resource_types
  tier          = "Standard"
  resource_type = each.value
}

resource "azurerm_policy_assignment" "sc_auto_enable" {
  name                 = "security_center"
  location             = azurerm_resource_group.security_center.location
  scope                = data.azurerm_management_group.target.id
  policy_definition_id = join("", [
    "/providers/Microsoft.Authorization/policyDefinitions/",
    "ac076320-ddcf-4066-b451-6154267e8ad2"
  ])

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_policy_remediation" "sc_auto_enable" {
  name                 = "security_center"
  scope                = azurerm_policy_assignment.sc_auto_enable.scope
  policy_assignment_id = azurerm_policy_assignment.sc_auto_enable.id
}
