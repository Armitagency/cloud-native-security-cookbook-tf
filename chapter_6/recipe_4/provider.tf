provider "google" {
  project     = var.project
  region      = var.region
  credentials = "/Users/josh/Downloads/armitagency.json"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2"
    }
  }
}
