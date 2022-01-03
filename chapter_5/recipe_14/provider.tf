provider "aws" {}

provider "aws" {
  alias = "consumer"
  assume_role {
    role_arn = join("", [
      "arn:aws:iam::",
      var.consumer_account_id,
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
