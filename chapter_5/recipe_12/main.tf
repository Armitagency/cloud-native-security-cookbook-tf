data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "a" {
  name     = "application"
  location = var.location
}

locals {
  application_url  = join("-", [
    "application",
    data.azurerm_subscription.current.subscription_id
  ])
}

resource "azurerm_frontdoor" "application" {
  name                                         = var.application_name
  friendly_name                                = var.application_name
  resource_group_name                          = azurerm_resource_group.a.name
  enforce_backend_pools_certificate_name_check = false

  backend_pool {
    name = "backend"
    backend {
      host_header = "${local.application_url}.azurewebsites.net"
      address     = "${local.application_url}.azurewebsites.net"
      http_port   = 80
      https_port  = 443
    }

    load_balancing_name = "application"
    health_probe_name   = "application"
  }

  routing_rule {
    name               = "default"
    accepted_protocols = ["Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = ["frontend"]
    forwarding_configuration {
      forwarding_protocol = "HttpsOnly"
      backend_pool_name   = "backend"
    }
  }

  frontend_endpoint {
    name      = "frontend"
    host_name = "${var.application_name}.azurefd.net"
  }

  backend_pool_health_probe {
    name = "application"
  }

  backend_pool_load_balancing {
    name = "application"
  }
}

resource "azurerm_app_service_plan" "application" {
  name                = "application-service-plan"
  location            = azurerm_resource_group.a.location
  resource_group_name = azurerm_resource_group.a.name
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "application" {
  name = local.application_url
  https_only = true

  site_config {
    linux_fx_version = "DOCKER|appsvcsample/static-site:latest"
    always_on        = true

    ip_restriction {
      service_tag = "AzureFrontDoor.Backend"

      headers {
        x_azure_fdid = [
          azurerm_frontdoor.application.header_frontdoor_id
        ]
      }
    }
  }

  location            = azurerm_resource_group.a.location
  resource_group_name = azurerm_resource_group.a.name
  app_service_plan_id = azurerm_app_service_plan.application.id
}

resource "azurerm_frontdoor_firewall_policy" "application" {
  name                              = "application"
  resource_group_name               = azurerm_resource_group.a.name
  enabled                           = true
  mode                              = "Prevention"

  managed_rule {
    type    = "DefaultRuleSet"
    version = "1.0"
  }
}

output "application_url" {
  value = "https://${var.application_name}.azurefd.net"
}
