resource "google_project_service" "osconfig" {
  service            = "osconfig.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "containerscanning" {
  service            = "containerscanning.googleapis.com"
  disable_on_destroy = false
}

resource "google_compute_project_metadata_item" "osconfig" {
  key   = "enable-osconfig"
  value = "TRUE"
}

resource "google_compute_project_metadata_item" "guest_attrs" {
  key   = "enable-guest-attributes"
  value = "TRUE"
}

resource "google_project_service_identity" "containerscanning" {
  provider = google-beta
  service  = "containerscanning.googleapis.com"
}

resource "google_project_service_identity" "osconfig" {
  provider = google-beta
  service  = "osconfig.googleapis.com"
}

resource "google_project_iam_member" "containerscanning" {
  project = var.project
  role    = "roles/containeranalysis.ServiceAgent"
  member = join("", [
    "serviceAccount:",
    google_project_service_identity.containerscanning.email
  ])
}

resource "google_project_iam_member" "osconfig" {
  project = var.project
  role    = "roles/osconfig.serviceAgent"
  member = join("", [
    "serviceAccount:",
    google_project_service_identity.osconfig.email
  ])
}

resource "google_compute_instance" "bastion" {
  name                      = "bastion"
  machine_type              = "f1-micro"
  zone                      = var.zone
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10-buster-v20211105"
    }
  }

  network_interface {
    network = "default"

    access_config {}
  }

  service_account {
    email  = google_service_account.bastion.email
    scopes = ["cloud-platform"]
  }
}

resource "google_service_account" "bastion" {
  account_id   = "bastion"
  display_name = "bastion"
}
