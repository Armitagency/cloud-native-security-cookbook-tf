data "azurerm_subscription" "subscription" {
  for_each        = toset(var.sensitive_subscription_ids)
  subscription_id = each.value
}

resource "azurerm_policy_assignment" "storage_cmk" {
  for_each = toset(var.sensitive_subscription_ids)
  name     = "storage-cmk-${each.value}"
  scope    = data.azurerm_subscription.subscription[each.value].id
  policy_definition_id = join("", [
    "/providers/Microsoft.Authorization/policyDefinitions/",
    "b5ec538c-daa0-4006-8596-35468b9148e8"
  ])
}

resource "azurerm_policy_assignment" "postgres_cmk" {
  for_each = toset(var.sensitive_subscription_ids)
  name     = "postgres-cmk-${each.value}"
  scope    = data.azurerm_subscription.subscription[each.value].id
  policy_definition_id = join("", [
    "/providers/Microsoft.Authorization/policyDefinitions/",
    "18adea5e-f416-4d0f-8aa8-d24321e3e274"
  ])
}

resource "azurerm_policy_assignment" "disk_cmk" {
  for_each = toset(var.sensitive_subscription_ids)
  name     = "disk-cmk-${each.value}"
  scope    = data.azurerm_subscription.subscription[each.value].id
  policy_definition_id = join("", [
    "/providers/Microsoft.Authorization/policyDefinitions/",
    "702dd420-7fcc-42c5-afe8-4026edd20fe0"
  ])
}
