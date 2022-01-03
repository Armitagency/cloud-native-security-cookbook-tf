resource "random_password" "password" {
  for_each = var.users
  length   = 16
  special  = true
}

resource "azuread_user" "this" {
  for_each              = var.users
  force_password_change = true
  display_name          = each.value.display_name
  password              = random_password.password[each.key].result
  user_principal_name   = each.key
}

resource "azuread_group" "target_read_only" {
  display_name = "${data.azurerm_subscription.target.display_name}ReadOnly"
  members = [
    for user in azuread_user.this : user.object_id
  ]
}

data "azurerm_subscription" "target" {
  subscription_id = var.target_subscription_id
}

resource "azurerm_role_assignment" "target_read_only" {
  scope                = data.azurerm_subscription.target.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.target_read_only.object_id
}

output "passwords" {
  sensitive = true
  value     = [
    for user in azuread_user.this : {(user.user_principal_name) = user.password}
  ]
}
