provider "aws" {}

provider "aws" {
  alias = "delegated_admin_account"
  assume_role {
    role_arn = join("", [
      "arn:aws:iam::",
      var.delegated_admin_account,
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
