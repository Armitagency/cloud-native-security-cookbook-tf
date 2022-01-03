provider "aws" {
  region  = var.region
}

provider "aws" {
  alias = "target"
  region  = var.region
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
