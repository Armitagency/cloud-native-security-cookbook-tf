----
data "azurerm_management_group" "root" {
  name = var.root_management_group_uuid
}

resource "azurerm_policy_assignment" "root_region_lock" {
  name                 = "root-region-lock"
  scope                = data.azurerm_management_group.root.id
  policy_definition_id = join("", [
    "providers/Microsoft.Authorization/policyDefinitions/",
    "e56962a6-4747-49cd-b67b-bf8b01975c4c"
  ])

  parameters = <<PARAMETERS
{
  "listOfAllowedLocations": {
    "value": ${var.allowed_locations}
  }
}
PARAMETERS

}
