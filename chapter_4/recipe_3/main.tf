resource "random_string" "key_vault" {
  length  = 16
  special = false
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "encrypted_blobs" {
  name     = "encrypted-blobs"
  location = var.location
}

resource "azurerm_key_vault" "keys" {
  name                        = random_string.key_vault.result
  location                    = azurerm_resource_group.encrypted_blobs.location
  resource_group_name         = azurerm_resource_group.encrypted_blobs.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  sku_name                    = "standard"
}

resource "azurerm_key_vault_key" "blob" {
  name         = "blobby"
  key_vault_id = azurerm_key_vault.keys.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
}

resource "azurerm_key_vault_access_policy" "client" {
  key_vault_id = azurerm_key_vault.keys.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions    = ["get", "create", "delete"]
  secret_permissions = ["get"]
}
