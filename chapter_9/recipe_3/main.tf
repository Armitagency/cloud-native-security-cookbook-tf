resource "azurerm_resource_group" "before" {
  name     = "before"
  location = var.location
}

resource "azurerm_resource_group" "after" {
  name     = "after"
  location = var.location
}

resource "azurerm_app_service_plan" "this" {
  name                = "this"
  location            = azurerm_resource_group.before.location
  resource_group_name = azurerm_resource_group.before.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

output "move_command" {
  value = join(" ", [
    "az resource move --destination-group",
    azurerm_resource_group.after.name,
    "--ids",
    azurerm_app_service_plan.this.id
  ])
}

output "import_command" {
  value = join(" ", [
    "terraform import azurerm_app_service_plan.this",
    replace(
      azurerm_app_service_plan.this.id,
      azurerm_resource_group.before.name,
      azurerm_resource_group.after.name
    )
  ])
}
