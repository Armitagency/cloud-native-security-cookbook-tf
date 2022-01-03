resource "google_service_account" "bastion" {
  account_id   = "bastion"
  display_name = "bastion"
}

resource "google_compute_firewall" "ssh-target" {
  name      = "ssh-ingress-target"
  network   = google_compute_network.this.name
  direction = "INGRESS"
  priority  = 1000
  allow {
    protocol = "TCP"
    ports    = ["22"]
  }

  source_ranges = [
    "35.235.240.0/20"
  ]

  target_service_accounts = [
    google_service_account.bastion.email
  ]
}

resource "google_compute_firewall" "http-target" {
  name      = "http-egress"
  network   = google_compute_network.this.name
  direction = "EGRESS"
  priority  = 1000
  allow {
    protocol = "TCP"
    ports    = ["80"]
  }

  destination_ranges = [
    google_compute_subnetwork.subnet[var.region].ip_cidr_range
  ]

  target_service_accounts = [
    google_service_account.bastion.email
  ]
}

resource "google_compute_instance" "bastion" {
  name                      = "bastion"
  machine_type              = "f1-micro"
  zone                      = "europe-west1-b"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable-89-16108-470-25"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet[var.region].name
  }

  service_account {
    email  = google_service_account.bastion.email
    scopes = ["cloud-platform"]
  }
}
