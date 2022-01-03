provider "google" {
  project = var.project
  region  = var.region
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4"
    }
  }
}
