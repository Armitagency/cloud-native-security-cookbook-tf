provider "aws" {
  alias = "auth_account"
  assume_role {
    role_arn = join("", [
      "arn:aws:iam::",
      var.auth_account_id,
      ":role/",
      var.cross_account_role
    ])
  }
}

provider "aws" {
  alias = "target_account"
  assume_role {
    role_arn = join("", [
      "arn:aws:iam::",
      var.target_account_id,
      ":role/",
      var.cross_account_role
    ])
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
