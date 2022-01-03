resource "azurerm_disk_encryption_set" "des" {
  name                = "des"
  resource_group_name = azurerm_resource_group.encrypted_blobs.name
  location            = azurerm_resource_group.encrypted_blobs.location
  key_vault_key_id    = azurerm_key_vault_key.blob.id

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_key_vault_access_policy" "disk" {
  key_vault_id = azurerm_key_vault.keys.id

  tenant_id = azurerm_disk_encryption_set.des.identity.0.tenant_id
  object_id = azurerm_disk_encryption_set.des.identity.0.principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]
}

resource "azurerm_managed_disk" "encrypted" {
  name                   = "encryption-test"
  location               = azurerm_resource_group.encrypted_blobs.location
  resource_group_name    = azurerm_resource_group.encrypted_blobs.name
  storage_account_type   = "Standard_LRS"
  create_option          = "Empty"
  disk_size_gb           = "1"
  disk_encryption_set_id = azurerm_disk_encryption_set.des.id
}
