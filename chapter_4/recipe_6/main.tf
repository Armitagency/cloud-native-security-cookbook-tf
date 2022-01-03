resource "azurerm_resource_group" "csks" {
  name     = "csks"
  location = var.location
}

resource "azurerm_storage_account" "csk" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.csks.name
  location                 = azurerm_resource_group.csks.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "csk" {
  name                  = "csk"
  storage_account_name  = azurerm_storage_account.csk.name
  container_access_type = "private"
}

output "connection_string" {
  value     = azurerm_storage_account.csk.primary_connection_string
  sensitive = true
}

output "container_name" {
  value = azurerm_storage_container.csk.name
}
