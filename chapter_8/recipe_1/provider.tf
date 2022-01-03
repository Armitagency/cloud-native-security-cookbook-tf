provider "google" {
  project               = var.project
  billing_project       = var.project
  user_project_override = true
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3"
    }
  }
}
