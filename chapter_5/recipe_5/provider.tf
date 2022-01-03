provider "aws" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2"
    }
  }
}
