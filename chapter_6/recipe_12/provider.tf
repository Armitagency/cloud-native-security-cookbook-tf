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
  subscription_id = var.subscription_id
}
