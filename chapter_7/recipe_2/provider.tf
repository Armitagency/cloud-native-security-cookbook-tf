provider "aws" {
  region = var.region

  default_tags {
    tags = {
      cost_center         = var.cost_center
      data_classification = var.data_classification
    }
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3"
    }
  }
}
