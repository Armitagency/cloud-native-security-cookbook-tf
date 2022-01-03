provider "google" {
  project     = var.project
  region      = var.region
  zone        = "${var.region}-${var.zone}"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4"
    }
  }
}
