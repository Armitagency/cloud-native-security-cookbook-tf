data "azurerm_subscription" "current" {}

locals {
  policy_ids = [
    "b7ddfbdc-1260-477d-91fd-98bd9be789a6",
    "e802a67a-daf5-4436-9ea6-f6d821dd0c5d",
    "d158790f-bfb0-486c-8631-2dc6b4e8e6af",
    "399b2637-a50f-4f95-96f8-3a145476eb15",
    "4d24b6d4-5e53-4a4f-a7f4-618fa573ee4b",
    "9a1b8c48-453a-4044-86c3-d8bfd823e4f5",
    "6d555dd1-86f2-4f1c-8ed7-5abae7c6cbab",
    "22bee202-a82f-4305-9a2a-6d7f44d4dedb",
    "404c3081-a854-4457-ae30-26a93ef643f9",
    "8cb6aa8b-9e41-4f4e-aa25-089a7ac2581e",
    "f9d614c5-c173-4d56-95a7-b4437057d193",
    "f0e6e85b-9b9f-4a4b-b67b-f730d42f1b0b",
    "a4af4a39-4135-47fb-b175-47fbdf85311d",
  ]
  policy_assignments = azurerm_subscription_policy_assignment.transit
}

resource "azurerm_subscription_policy_assignment" "transit" {
  count                = length(local.policy_ids)
  name                 = "transit${count.index}"
  policy_definition_id = join("", [
    "/providers/Microsoft.Authorization/policyDefinitions/",
    local.policy_ids[count.index]
  ])
  subscription_id      = data.azurerm_subscription.current.id
}

resource "azurerm_policy_remediation" "transit" {
  count                = length(local.policy_ids)
  name                 = "transit${count.index}"
  scope                = data.azurerm_subscription.current.id
  policy_assignment_id = local.policy_assignments[count.index].id
}
