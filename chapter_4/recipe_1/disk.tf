resource "google_service_account" "sensitive" {
  account_id   = "sensitive-data-service-account"
  display_name = "Sensitive Data Handler"
}

resource "google_service_account_iam_policy" "sensitive" {
  service_account_id = google_service_account.sensitive.name
  policy_data        = data.google_iam_policy.sa.policy_data
}

data "google_client_openid_userinfo" "me" {}

data "google_iam_policy" "sa" {
  binding {
    role = "roles/iam.serviceAccountUser"

    members = [
      "user:${data.google_client_openid_userinfo.me.email}",
    ]
  }
}

resource "google_kms_crypto_key_iam_member" "service_account_use" {
  crypto_key_id = google_kms_crypto_key.key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${google_service_account.sensitive.email}"
}

resource "google_compute_disk" "encrypted" {
  name = "encrypted"
  size = "10"
  type = "pd-standard"
  zone = "${var.region}-a"
  disk_encryption_key {
    kms_key_self_link       = google_kms_crypto_key.key.id
    kms_key_service_account = google_service_account.sensitive.email
  }

  depends_on = [google_kms_crypto_key_iam_member.service_account_use]
}
