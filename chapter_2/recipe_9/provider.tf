provider "azuread" {}

provider "azurerm" {
  features {}
}

provider "random" {}

terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 1"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }
  }
}
