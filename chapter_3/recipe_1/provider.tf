provider "google" {
  project = var.project_id
  region  = var.region
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
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2"
    }
  }
}
