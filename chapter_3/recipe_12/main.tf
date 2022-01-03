resource "azurerm_resource_group" "resource_inventory" {
  name     = "resource_inventory"
  location = var.location
}

resource "azurerm_resource_group_template_deployment" "resource_inventory" {
  name                = "resource_inventory"
  resource_group_name = azurerm_resource_group.resource_inventory.name
  deployment_mode     = "Complete"
  template_content    = <<TEMPLATE
{
  "contentVersion": "1.0.0.0",
  "parameters": {
    "workbookDisplayName": {
      "type": "string",
      "defaultValue": "Resource Inventory",
      "metadata": {
        "description": "The friendly name for the workbook."
      }
    },
    "workbookType": {
      "type": "string",
      "defaultValue": "workbook",
      "metadata": {
        "description": "The gallery that the workbook will been shown under.""
      }
    },
    "workbookSourceId": {
      "type": "string",
      "defaultValue": "Azure Monitor",
      "metadata": {
        "description": "The id of resource instance"
      }
    },
    "workbookId": {
      "type": "string",
      "defaultValue": "[newGuid()]",
      "metadata": {
        "description": "The unique guid for this workbook instance"
      }
    }
  },
  "resources": [
    {
      "name": "[parameters('workbookId')]",
      "type": "microsoft.insights/workbooks",
      "location": "[resourceGroup().location]",
      "apiVersion": "2018-06-17-preview",
      "dependsOn": [],
      "kind": "shared",
      "properties": {
        "displayName": "[parameters('workbookDisplayName')]",
        "serializedData": ${jsonencode(data.local_file.workbook.content)},
        "version": "1.0",
        "sourceId": "[parameters('workbookSourceId')]",
        "category": "[parameters('workbookType')]"
      }
    }
  ],
  "outputs": {
    "workbookId": {
      "type": "string",
      "value": "[resourceId('microsoft.insights/workbooks', parameters('workbookId'))]"
    }
  },
  "$schema": join("", [
    "http://schema.management.azure.com/",
    "schemas/2015-01-01/deploymentTemplate.json#"
  ])
}
TEMPLATE
}

output "workbooks_url" {
  value = join("", [
    "https://portal.azure.com/#blade/",
    "Microsoft_Azure_Monitoring/AzureMonitoringBrowseBlade/",
    "workbooks"
  ])
}
