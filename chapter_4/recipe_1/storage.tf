data "google_project" "current" {}

resource "google_storage_bucket" "encrypted" {
  name          = "${data.google_project.current.project_id}-encrypted"
  force_destroy = true
  location      = var.region
  encryption {
    default_kms_key_name = google_kms_crypto_key.key.id
  }

  depends_on = [google_kms_crypto_key_iam_member.storage_binding]
}

data "google_storage_project_service_account" "this" {}

resource "google_kms_crypto_key_iam_member" "storage_binding" {
  crypto_key_id = google_kms_crypto_key.key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = join("",[
    "serviceAccount:",
    data.google_storage_project_service_account.this.email_address
  ])
}
