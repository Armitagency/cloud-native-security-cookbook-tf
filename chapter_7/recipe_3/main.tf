locals {
  tags = {
    cost_center         = var.cost_center
    data_classification = var.data_classification
  }
}

resource "azurerm_resource_group" "this" {
  name     = "tagging-rg"
  location = var.location
  tags     = local.tags
}

resource "azurerm_storage_account" "this" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  tags                     = local.tags
}
