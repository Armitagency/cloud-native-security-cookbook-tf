data "google_project" "current" {}

resource "google_storage_bucket" "csek" {
  name          = "${data.google_project.current.project_id}-csek"
  force_destroy = true
  location      = var.region
}

output "storage_bucket_name" {
  value = google_storage_bucket.csek.name
}
