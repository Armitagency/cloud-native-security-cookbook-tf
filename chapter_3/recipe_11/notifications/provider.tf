provider "aws" {
  alias = "central"
  assume_role {
    role_arn = "arn:aws:iam::${var.central_account}:role/${var.cross_account_role}"
  }
}

provider "aws" {
  alias = "target"
  assume_role {
    role_arn = "arn:aws:iam::${var.target_account}:role/${var.cross_account_role}"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.53.0"
    }
  }
}
