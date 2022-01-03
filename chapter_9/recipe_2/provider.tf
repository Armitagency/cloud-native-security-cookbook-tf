provider "aws" {}

provider "aws" {
  alias = "red"
  assume_role {
    role_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/red_team"
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
