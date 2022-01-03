resource "azurerm_resource_group" "workload" {
  name     = "workload"
  location = var.location
}

data "azuread_user" "access_admin" {
  user_principal_name = var.upn
}

resource "azurerm_role_assignment" "access_admin" {
  scope                = azurerm_resource_group.workload.id
  role_definition_name = "User Access Administrator"
  principal_id         = data.azuread_user.access_admin.object_id
}

resource "azurerm_policy_definition" "psep" {
  name         = "prevent-self-edit-permissions"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Prevent self editing of permissions"

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
            "field": "Microsoft.Authorization/roleAssignments/principalId",
            "equals": "[parameters('principalId')]"
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
  "principalId": {
    "type": "string",
    "defaultValue": "",
    "metadata": {
      "description": "The principal ID",
      "displayName": "The principal ID"
    }
  }
}
PARAMETERS
}

resource "azurerm_resource_group_policy_assignment" "prevent_self_edit" {
  name                 = "prevent-self-edit"
  resource_group_id    = azurerm_resource_group.workload.id
  policy_definition_id = azurerm_policy_definition.psep.id
  parameters = <<PARAMETERS
{
  "principalId": {
    "value": "${data.azuread_user.access_admin.object_id}"
  }
}
PARAMETERS

  depends_on = [
    azurerm_role_assignment.access_admin
  ]
}
