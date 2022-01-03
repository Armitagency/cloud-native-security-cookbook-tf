provider "aws" {}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.44.0"
    }
  }
}
