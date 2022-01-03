provider "google" {
  project = var.project
}

provider "google-beta" {
  project = var.project
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4"
    }
  }
}
