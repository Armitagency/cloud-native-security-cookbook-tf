provider "aws" {
  alias = "transit"
}

provider "aws" {
  alias = "spoke1"
  assume_role {
    role_arn = join("", [
      "arn:aws:iam::",
      var.spoke1_account_id,
      ":role/",
      var.cross_account_role
    ])
  }
}

provider "aws" {
  alias = "spoke2"
  assume_role {
    role_arn = join("", [
      "arn:aws:iam::",
      var.spoke2_account_id,
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
