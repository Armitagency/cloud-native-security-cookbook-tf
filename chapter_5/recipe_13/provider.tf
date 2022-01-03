provider "google" {
  project = var.project
}

provider "google" {
  alias   = "provider"
  project = var.provider_project
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3"
    }
  }
}
