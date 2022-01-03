resource "azurerm_policy_definition" "prevent_specific_role_assignment" {
  name         = "prevent-specific-role-assignment"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Prevent specific role assignment"

  metadata = <<METADATA
{
  "category": "IAM"
}
METADATA

  policy_rule = <<RULE
{
  "if": {
    "anyOf": [
      {
        "allOf": [
          {
            "field": "type",
            "equals": "Microsoft.Authorization/roleAssignments"
          },
          {
            "field": "Microsoft.Authorization/roleAssignments/roleDefinitionId",
            "equals": "[parameters('definitionId')]"
          }
        ]
      }
    ]
  },
  "then": {
    "effect": "Deny"
  }
}
RULE

  parameters = <<PARAMETERS
{
  "definitionId": {
    "type": "string",
    "defaultValue": "",
    "metadata": {
      "description": "The role definition ID to prevent",
      "displayName": "The role definition ID to prevent"
    }
  }
}
PARAMETERS
}
