provider "google" {
  project = var.project
  region  = var.region
}

provider "google" {
  alias   = "hub"
  region  = var.region
  project = var.hub_project
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3"
    }
  }
}
