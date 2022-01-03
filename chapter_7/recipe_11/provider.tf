provider "aws" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3"
    }
  }
}
