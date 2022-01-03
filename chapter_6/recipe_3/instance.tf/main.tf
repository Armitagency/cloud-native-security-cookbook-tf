data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

resource "azurerm_network_interface" "primary" {
  name                = "${var.instance_name}-primary"
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  name                = var.instance_name
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.primary.id,
  ]


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_encryption_set_id = azurerm_disk_encryption_set.des.id
  }

  admin_ssh_key {
    username   = "adminuser"
    public_key = file(var.ssh_key_path)
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  depends_on = [
    azurerm_role_assignment.crypto_access
  ]
}

resource "random_string" "key_vault" {
  length  = 16
  number = false
  special = false
}

resource "azurerm_key_vault" "keys" {
  name                        = random_string.key_vault.result
  location                    = data.azurerm_resource_group.this.location
  resource_group_name         = data.azurerm_resource_group.this.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  enable_rbac_authorization   = true
  enabled_for_disk_encryption = true
  soft_delete_retention_days  = 7
  purge_protection_enabled    = true
  sku_name                    = "standard"
}

resource "azurerm_disk_encryption_set" "des" {
  name                = "des"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = data.azurerm_resource_group.this.location
  key_vault_key_id    = azurerm_key_vault_key.disk.id

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "crypto_officer" {
  scope                = azurerm_key_vault.keys.id
  role_definition_name = "Key Vault Crypto Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "user_reader" {
  scope                = azurerm_key_vault.keys.id
  role_definition_name = "Reader"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "des_reader" {
  scope                = azurerm_key_vault.keys.id
  role_definition_name = "Reader"
  principal_id         = azurerm_disk_encryption_set.des.identity.0.principal_id
}

resource "azurerm_role_assignment" "crypto_access" {
  scope                = azurerm_key_vault.keys.id
  role_definition_name = "Key Vault Crypto User"
  principal_id         = azurerm_disk_encryption_set.des.identity.0.principal_id
}

resource "azurerm_key_vault_key" "disk" {
  name         = "disk"
  key_vault_id = azurerm_key_vault.keys.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts     = ["decrypt", "encrypt", "sign", "unwrapKey", "verify", "wrapKey"]
}

resource "azurerm_managed_disk" "encrypted" {
  name                   = "${var.instance_name}-1"
  location               = data.azurerm_resource_group.this.location
  resource_group_name    = data.azurerm_resource_group.this.name
  storage_account_type   = "Standard_LRS"
  create_option          = "Empty"
  disk_size_gb           = "1"
  disk_encryption_set_id = azurerm_disk_encryption_set.des.id
}

resource "azurerm_virtual_machine_data_disk_attachment" "attachment" {
  managed_disk_id    = azurerm_managed_disk.encrypted.id
  virtual_machine_id = azurerm_linux_virtual_machine.this.id
  lun                = "10"
  caching            = "ReadWrite"
}
