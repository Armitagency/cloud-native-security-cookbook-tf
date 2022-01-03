provider "aws" {}

provider "aws" {
  alias = "delegated_admin"
  assume_role {
    role_arn = join("", [
      "arn:aws:iam::",
      var.delegated_admin_account_id,
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
