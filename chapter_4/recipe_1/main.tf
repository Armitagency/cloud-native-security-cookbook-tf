resource "google_project_service" "cloud_kms" {
  service = "cloudkms.googleapis.com"
}

resource "google_kms_key_ring" "keyring" {
  name       = "sensitive-data-keyring"
  location   = var.region
  depends_on = [google_project_service.cloud_kms]
}

resource "google_kms_crypto_key" "key" {
  name     = "sensitive-data-key"
  key_ring = google_kms_key_ring.keyring.id
}
