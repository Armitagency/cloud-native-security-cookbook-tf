resource "azurerm_resource_group" "backups" {
  name     = "backups"
  location = "West Europe"
}

resource "azurerm_recovery_services_vault" "this" {
  name                = "tfex-recovery-vault"
  location            = azurerm_resource_group.backups.location
  resource_group_name = azurerm_resource_group.backups.name
  sku                 = "Standard"
}

resource "azurerm_backup_policy_vm" "daily" {
  name                = "daily-vm-backups"
  resource_group_name = azurerm_resource_group.backups.name
  recovery_vault_name = azurerm_recovery_services_vault.this.name

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 14
  }
}

resource "azurerm_backup_protected_vm" "vm1" {
  resource_group_name = azurerm_resource_group.backups.name
  recovery_vault_name = azurerm_recovery_services_vault.this.name
  source_vm_id        = azurerm_linux_virtual_machine.inventory.id
  backup_policy_id    = azurerm_backup_policy_vm.daily.id
}
