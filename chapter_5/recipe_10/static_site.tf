resource "google_compute_backend_bucket" "static" {
  name        = "${var.project}-static"
  bucket_name = google_storage_bucket.static_site.name
  enable_cdn  = true
}

resource "google_storage_bucket" "static_site" {
  name     = "${var.project}-static"
  location = var.application_region
}
