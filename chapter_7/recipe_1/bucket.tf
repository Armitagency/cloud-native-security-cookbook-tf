locals {
  labels = {
    "cost_center"         = var.cost_center
    "data_classification" = var.data_classification
  }
}

resource "google_storage_bucket" "pii_bucket" {
  name          = var.bucket_name
  force_destroy = true

  labels = local.labels
}
