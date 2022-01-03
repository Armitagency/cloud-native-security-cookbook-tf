provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = "./auth/service_account.json"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3"
    }
  }
}
