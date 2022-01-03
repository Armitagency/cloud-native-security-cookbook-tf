resource "azurerm_resource_group" "workload" {
  name     = "workload"
  location = var.location
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.workload.location
  resource_group_name = azurerm_resource_group.workload.name
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.workload.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

module "encrypted_instance" {
  source              = "./instance"
  instance_name       = var.instance_name
  resource_group_name = azurerm_resource_group.workload.name
  ssh_key_path        = var.ssh_key_path
  subnet_id           = azurerm_subnet.example.id

  depends_on = [
    azurerm_resource_group.workload
  ]
}
