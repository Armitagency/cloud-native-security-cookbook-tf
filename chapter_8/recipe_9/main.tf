data "azurerm_subscription" "current" {}

resource "time_offset" "tomorrow" {
  offset_days = 1
}

locals {
  update_date = substr(time_offset.tomorrow.rfc3339, 0, 10)
  datetime = replace(
    "${local.update_date}T${var.update_time}",
    "/:/",
    "-"
  )
  classifications = [
    "Critical",
    "Other",
    "Security",
    "Unclassified"
  ]
}

resource "azurerm_resource_group_template_deployment" "linux" {
  name                = "linux-weekly-patching"
  resource_group_name = azurerm_resource_group.management.name

  template_content = <<DEPLOY
{
  "$schema": ${join("", [
    "https://schema.management.azure.com/,
    "schemas/2019-04-01/deploymentTemplate.json#"
  ])},
  "contentVersion": "1.0.0.0",
  "parameters": {},
  "resources": [
    {
      "type": ${join("/", [
        "Microsoft.Automation",
        "automationAccounts",
        "softwareUpdateConfigurations",
      ])},
      "apiVersion": "2019-06-01",
      "name": "${azurerm_automation_account.this.name}/linux-weekly",
      "properties": {
        "scheduleInfo": {
          "advancedSchedule": {
            "weekDays": [ "Friday" ]
          },
          "frequency": "Week",
          "interval": "1",
          "startTime": "${local.update_date}T${var.update_time}:00-00:00",
          "timeZone": "${var.time_zone}"
        },
        "updateConfiguration": {
          "duration": "PT2H",
          "linux": {
            "includedPackageClassifications": ${local.classifications},
            "rebootSetting": "IfRequired"
          },
          "operatingSystem": "Linux",
          "targets": {
            "azureQueries": [
              {
                "scope": [
                  "${data.azurerm_subscription.current.id}"
                ],
                "tagSettings": {
                  "filterOperator": "Any",
                  "tags": {
                    "${var.tag_key}": ${var.tag_values}
                  }
                }
              }
            ]
          }
        }
      }
    }
  ]
}
    DEPLOY

  deployment_mode = "Complete"
}
