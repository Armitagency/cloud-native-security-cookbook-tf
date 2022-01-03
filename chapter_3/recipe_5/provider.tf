provider "aws" {}

provider "aws" {
  alias = "logging"
  assume_role {
    role_arn = join("", [
      "arn:aws:iam::",
      var.logging_account_id,
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
