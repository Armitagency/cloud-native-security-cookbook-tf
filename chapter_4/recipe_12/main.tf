data "azurerm_client_config" "current" {}

data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "purview" {
  name     = "purview-resources"
  location = var.location
}

resource "azurerm_purview_account" "purview" {
  name                = var.purview_account_name
  resource_group_name = azurerm_resource_group.purview.name
  location            = azurerm_resource_group.purview.location
  sku_name            = "Standard_4"
}

resource "azurerm_role_assignment" "data_curator" {
  scope                = azurerm_purview_account.purview.id
  role_definition_name = "Purview Data Curator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "data_source_admin" {
  scope                = azurerm_purview_account.purview.id
  role_definition_name = "Purview Data Source Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_storage_account" "purview" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.purview.name
  location                 = azurerm_resource_group.purview.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_storage_container" "purview" {
  name                  = "purview"
  storage_account_name  = azurerm_storage_account.purview.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "sensitive" {
  name                   = var.filename
  content_type           = "text/plain"
  storage_account_name   = azurerm_storage_account.purview.name
  storage_container_name = azurerm_storage_container.purview.name
  type                   = "Block"
  source                 = var.filename
}

resource "azurerm_role_assignment" "reader" {
  scope                = azurerm_storage_account.purview.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_purview_account.purview.identity[0].principal_id
}

resource "local_file" "storage_account" {
  filename = "blob_storage.json"
  content  = <<CONTENT
{
    "id": "datasources/AzureStorage",
    "kind": "AzureStorage",
    "name": "AzureStorage",
    "properties": {
        "collection": null,
        "endpoint": "${azurerm_storage_account.purview.primary_blob_endpoint}",
        "location": "${azurerm_resource_group.purview.location}",
        "parentCollection": null,
        "resourceGroup": "${azurerm_resource_group.purview.name}",
        "resourceName": "${azurerm_storage_account.purview.name}",
        "subscriptionId": "${data.azurerm_subscription.current.subscription_id}"
    }
}
CONTENT
}

resource "local_file" "scan" {
  filename = "scan.json"
  content  = <<CONTENT
{
    "kind": "AzureStorageMsi",
    "properties": {
        "scanRulesetName": "AzureStorage",
        "scanRulesetType": "System"
    }
}
CONTENT
}

resource "null_resource" "add_data_source" {
  provisioner "local-exec" {
    command = join(" ", [
      "pv scan putDataSource",
      "--dataSourceName=AzureStorage",
      "--payload-file=${local_file.storage_account.filename}",
      "--purviewName ${azurerm_purview_account.purview.name}"
    ])
  }
}

resource "null_resource" "create_scan" {
  provisioner "local-exec" {
        command = join(" ", [
      "pv scan putScan",
      "--dataSourceName=AzureStorage",
      "--scanName=storage",
      "--payload-file=${local_file.scan.filename}",
      "--purviewName ${azurerm_purview_account.purview.name}"
    ])
  }

  depends_on = [
    null_resource.add_data_source
  ]
}

resource "null_resource" "run_scan" {
  provisioner "local-exec" {
    command = join(" ", [
      "pv scan runScan",
      "--dataSourceName=AzureStorage",
      "--scanName=storage",
      "--purviewName ${azurerm_purview_account.purview.name}"
    ])
  }

  depends_on = [
    null_resource.create_scan
  ]
}
