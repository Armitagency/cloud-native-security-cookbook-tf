provider "google" {
  project = var.project
}

provider "google" {
  alias       = "red_team"
  project     = var.project
  credentials = "./auth/red_team.json"
}

provider "google" {
  alias       = "blue_team"
  project     = var.project
  credentials = "./auth/blue_team.json"
}

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 3"
    }
  }
}
