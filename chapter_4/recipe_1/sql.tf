resource "google_compute_network" "vpc_network" {
  name = "vpc-network"
}

resource "google_sql_database_instance" "encrypted" {
  provider            = google-beta
  name                = "encrypted-instance"
  database_version    = "POSTGRES_13"
  region              = var.region
  deletion_protection = false
  encryption_key_name = google_kms_crypto_key.key.id
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      private_network = google_compute_network.vpc_network.id
    }
  }

  depends_on = [google_kms_crypto_key_iam_member.sql_binding]
}

resource "google_kms_crypto_key_iam_member" "sql_binding" {
  crypto_key_id = google_kms_crypto_key.key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = join("", [
    "serviceAccount:service-",
    data.google_project.current.number,
    "@gcp-sa-cloud-sql.iam.gserviceaccount.com"
  ])

  depends_on = [null_resource.create_database_service_account]
}

resource "null_resource" "create_database_service_account" {
  provisioner "local-exec" {
    command = join(" ", [
      "gcloud beta services identity create",
      "--project=${var.project_id}",
      "--service=sqladmin.googleapis.com"
    ])
  }
}
