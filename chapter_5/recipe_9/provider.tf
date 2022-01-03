terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azurerm" {
  alias           = "hub"
  subscription_id = var.hub_subscription_id

  features {}
}
