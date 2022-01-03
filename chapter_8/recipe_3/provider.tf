terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2"
    }
  }
}

provider "azurerm" {
  features {}
}
