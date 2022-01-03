resource "azurerm_resource_group" "zap" {
  name     = "zap"
  location = var.location
}

resource "azurerm_container_group" "zap" {
  name                = "zap"
  location            = azurerm_resource_group.zap.location
  resource_group_name = azurerm_resource_group.zap.name
  ip_address_type     = "public"
  os_type             = "Linux"
  restart_policy      = "Never"
  exposed_port        = []

  container {
    name   = "zap"
    image  = "owasp/zap2docker-stable"
    cpu    = "0.5"
    memory = "1.5"
    commands = [
      "zap-baseline.py",
      "-t",
      var.target_url,
      "-I"
    ]

    ports {
      port     = 443
      protocol = "TCP"
    }
  }
}
