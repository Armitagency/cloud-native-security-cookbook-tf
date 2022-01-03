resource "azurerm_management_group" "team" {
  display_name               = var.team_name
  parent_management_group_id = var.management_group_parent_id

  subscription_ids = [
    azurerm_subscription.production.subscription_id,
    azurerm_subscription.preproduction.subscription_id,
    azurerm_subscription.development.subscription_id,
    azurerm_subscription.shared.subscription_id
  ]
}

data "azurerm_billing_enrollment_account_scope" "root" {
  billing_account_name    = var.billing_account_name
  enrollment_account_name = var.enrollment_account_name
}

resource "azurerm_subscription" "production" {
  billing_scope_id  = data.azurerm_billing_enrollment_account_scope.root[0].id
  subscription_name = "${var.team_name}Production"
}

resource "azurerm_subscription" "preproduction" {
  billing_scope_id  = data.azurerm_billing_enrollment_account_scope.root[0].id
  subscription_name = "${var.team_name}Preproduction"
}

resource "azurerm_subscription" "development" {
  billing_scope_id  = data.azurerm_billing_enrollment_account_scope.root[0].id
  subscription_name = "${var.team_name}Development"
}

resource "azurerm_subscription" "shared" {
  billing_scope_id  = data.azurerm_billing_enrollment_account_scope.root[0].id
  subscription_name = "${var.team_name}Shared"
}
