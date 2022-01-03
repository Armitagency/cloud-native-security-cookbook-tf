provider "google" {
  project = var.project_id
  region  = var.region
}

provider "google-beta" {
  project = var.project_id
  region  = var.region
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 3"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3"
    }
  }
}
