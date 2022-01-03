data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "ssh_keys" {
  name                = "ssh-keys"
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name

  sku_name  = "standard"
  tenant_id = data.azurerm_client_config.current.tenant_id
}

resource "azurerm_key_vault_secret" "id_rsa" {
  name         = "ssh-private-key"
  value        = file("~/.ssh/id_rsa")
  key_vault_id = azurerm_key_vault.ssh_keys.id
}
