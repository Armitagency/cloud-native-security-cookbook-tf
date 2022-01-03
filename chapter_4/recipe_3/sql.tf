resource "azurerm_key_vault_access_policy" "server" {
  key_vault_id = azurerm_key_vault.keys.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_postgresql_server.database.identity.0.principal_id

  key_permissions    = ["get", "unwrapkey", "wrapkey"]
  secret_permissions = ["get"]
}

resource "random_password" "database" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "azurerm_postgresql_server" "database" {
  name                = "encrypted-database"
  location            = azurerm_resource_group.encrypted_blobs.location
  resource_group_name = azurerm_resource_group.encrypted_blobs.name

  administrator_login          = "postgres"
  administrator_login_password = random_password.database.result

  sku_name   = "GP_Gen5_2"
  version    = "11"
  storage_mb = 5120

  ssl_enforcement_enabled = true

  threat_detection_policy {
    disabled_alerts      = []
    email_account_admins = false
    email_addresses      = []
    enabled              = true
    retention_days       = 0
  }

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_postgresql_server_key" "database" {
  server_id        = azurerm_postgresql_server.database.id
  key_vault_key_id = azurerm_key_vault_key.blob.id
}

output "database_password" {
  value     = azurerm_postgresql_server.database.administrator_login_password
  sensitive = true
}
