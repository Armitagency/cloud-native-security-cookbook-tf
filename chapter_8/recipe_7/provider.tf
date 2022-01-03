provider "google-beta" {
  project = var.project
}

terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4"
    }
  }
}
