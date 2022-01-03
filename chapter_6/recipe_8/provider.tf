provider "aws" {}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3"
    }
  }
  backend "s3" {
    bucket = "armitagency-state"
    key    = "terraform.tfstate"
  }
}
