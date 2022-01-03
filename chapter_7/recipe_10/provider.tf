provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google" {
  alias       = "cloud_assets"
  project     = var.project_id
  region      = var.region
  credentials = "./auth/cloud_assets.json"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3"
    }
  }
}
