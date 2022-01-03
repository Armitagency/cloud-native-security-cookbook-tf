terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }
    archive = {
      source = "hashicorp/archive"
      version = "~> 2"
    }
  }
}

provider "azurerm" {
  features {}
}
