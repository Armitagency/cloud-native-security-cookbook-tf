data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "example" {
  name     = "example"
  location = "West Europe"
}

resource "azurerm_postgresql_server" "example" {
  name                = "example"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  sku_name = "B_Gen5_2"

  storage_mb                   = 5120
  backup_retention_days        = 7
  geo_redundant_backup_enabled = false
  auto_grow_enabled            = true

  administrator_login          = "psqladmin"
  administrator_login_password = "H@Sh1CoR3!"
  version                      = "9.5"
  ssl_enforcement_enabled      = true
}

resource "azurerm_postgresql_firewall_rule" "example" {
  name                = "AllowAllWindowsAzureIps"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_postgresql_server.example.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

resource "azurerm_postgresql_database" "example" {
  name                = "example"
  resource_group_name = azurerm_resource_group.example.name
  server_name         = azurerm_postgresql_server.example.name
  charset             = "UTF8"
  collation           = "English_United States.1252"
}

resource "azurerm_data_protection_backup_vault" "example" {
  name                = "example"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  datastore_type      = "VaultStore"
  redundancy          = "LocallyRedundant"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_key_vault" "example" {
  name                       = "example"
  location                   = azurerm_resource_group.example.location
  resource_group_name        = azurerm_resource_group.example.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "premium"
  soft_delete_retention_days = 7

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    key_permissions = ["create", "get"]

    secret_permissions = [
      "set",
      "get",
      "delete",
      "purge",
      "recover"
    ]
  }

  access_policy {
    tenant_id = azurerm_data_protection_backup_vault.example.identity.0.tenant_id
    object_id = azurerm_data_protection_backup_vault.example.identity.0.principal_id

    key_permissions = ["create", "get"]

    secret_permissions = [
      "set",
      "get",
      "delete",
      "purge",
      "recover"
    ]
  }
}

resource "azurerm_key_vault_secret" "example" {
  name         = "example"
  value        = "Server=${azurerm_postgresql_server.example.name}.postgres.database.azure.com;Database=${azurerm_postgresql_database.example.name};Port=5432;User Id=psqladmin@${azurerm_postgresql_server.example.name};Password=H@Sh1CoR3!;Ssl Mode=Require;"
  key_vault_id = azurerm_key_vault.example.id
}

resource "azurerm_data_protection_backup_policy_postgresql" "example" {
  name                            = "example"
  resource_group_name             = azurerm_resource_group.example.name
  vault_name                      = azurerm_data_protection_backup_vault.example.name
  backup_repeating_time_intervals = ["R/2021-05-23T02:30:00+00:00/P1W"]
  default_retention_duration      = "P4M"
}

resource "azurerm_role_assignment" "example" {
  scope                = azurerm_postgresql_server.example.id
  role_definition_name = "Reader"
  principal_id         = azurerm_data_protection_backup_vault.example.identity.0.principal_id
}

resource "azurerm_data_protection_backup_instance_postgresql" "example" {
  name                                    = "example"
  location                                = azurerm_resource_group.example.location
  vault_id                                = azurerm_data_protection_backup_vault.example.id
  database_id                             = azurerm_postgresql_database.example.id
  backup_policy_id                        = azurerm_data_protection_backup_policy_postgresql.example.id
  database_credential_key_vault_secret_id = azurerm_key_vault_secret.example.versionless_id
}
