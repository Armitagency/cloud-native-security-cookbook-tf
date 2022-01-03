provider "aws" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2"
    }
  }
}
