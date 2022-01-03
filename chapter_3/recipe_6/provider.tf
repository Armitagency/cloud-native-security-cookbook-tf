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
  alias = "delivery"
  features {}
  subscription_id = var.delivery_subscription_id
}

provider "azurerm" {
  alias = "central"
  features {}
  subscription_id = var.central_subscription_id
}
