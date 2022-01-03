resource "azurerm_key_vault_access_policy" "storage" {
  key_vault_id = azurerm_key_vault.keys.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_storage_account.sensitive.identity.0.principal_id

  key_permissions    = ["get", "unwrapkey", "wrapkey"]
  secret_permissions = ["get"]
}

resource "azurerm_storage_account" "sensitive" {
  name                     = "armitagencysensitive"
  resource_group_name      = azurerm_resource_group.encrypted_blobs.name
  location                 = azurerm_resource_group.encrypted_blobs.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_storage_account_customer_managed_key" "sensitive" {
  storage_account_id = azurerm_storage_account.sensitive.id
  key_vault_id       = azurerm_key_vault.keys.id
  key_name           = azurerm_key_vault_key.blob.name
}
