data "azurerm_subscription" "current" {}

resource "azurerm_policy_definition" "g_series_prevent" {
  name         = "Prevent G Series Virtual Machines"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Prevent G Series Virtual Machines"


  policy_rule = <<POLICY_RULE
{
  "if": {
    "allOf": [{
        "field": "type",
        "equals": "Microsoft.Compute/virtualMachines"
      },
      {
        "field": "Microsoft.Compute/virtualMachines/sku.name",
        "like": "Standard_G*"
      }
    ]
  },
  "then": {
    "effect": "deny"
  }
}
POLICY_RULE
}

resource "azurerm_subscription_policy_assignment" "g_series_prevent" {
  name                 = "g_series_prevent"
  policy_definition_id = azurerm_policy_definition.g_series_prevent.id
  subscription_id      = data.azurerm_subscription.current.id
}
