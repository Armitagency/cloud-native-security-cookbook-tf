provider "google" {
  project = var.project_id
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2"
    }
  }
}
