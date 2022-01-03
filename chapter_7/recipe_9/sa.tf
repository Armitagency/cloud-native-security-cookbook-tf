resource "azurerm_resource_group" "test" {
  name     = "test"
  location = "us"
}

resource "azurerm_storage_account" "test" {
  // checkov:skip=CKV2_AZURE_8
  resource_group_name       = azurerm_resource_group.test.name
  location                  = azurerm_resource_group.test.location
  name                      = "test"
  account_tier              = "Standard"
  account_replication_type  = "GRS"
  min_tls_version           = "TLS1_2"
  enable_https_traffic_only = true

  queue_properties {
    logging {
      delete                = true
      read                  = true
      write                 = true
      version               = "1.0"
      retention_policy_days = 10
    }
  }


  network_rules {
    default_action = "Deny"
  }
}

resource "azurerm_key_vault" "example" {
  name                = "examplekv"
  location            = "location"
  resource_group_name = "group"
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  purge_protection_enabled = true

  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
  }
}

resource "azurerm_key_vault_key" "example" {
  // checkov:skip=CKV_AZURE_112
  name            = "tfex-key"
  key_vault_id    = azurerm_key_vault.example.id
  key_type        = "RSA"
  key_size        = 2048
  key_opts        = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
  expiration_date = "2022-12-30T20:00:00Z"
}

resource "azurerm_storage_account_customer_managed_key" "key" {
  storage_account_id = azurerm_storage_account.test.id
  key_vault_id       = azurerm_key_vault.example.id
  key_name           = azurerm_key_vault_key.example.name
  key_version        = "1"
}
