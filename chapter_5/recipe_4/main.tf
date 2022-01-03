locals {
  compute_region = join("-", [
    split("-", var.instance_zone)[0],
    split("-", var.instance_zone)[1]
  ])
}

resource "google_project_service" "compute_api" {
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_compute_network" "this" {
  name                            = "network"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true

  depends_on = [
    google_project_service.compute_api,
  ]
}

resource "google_compute_subnetwork" "subnet" {
  for_each      = var.region_subnets
  name          = each.key
  ip_cidr_range = each.value
  network       = google_compute_network.this.id
  region        = each.key
}

resource "google_compute_firewall" "default_ingress_deny" {
  name      = "default-ingress-deny"
  network   = google_compute_network.this.name
  direction = "INGRESS"
  priority  = 65533
  deny {
    protocol = "all"
  }
}

resource "google_compute_firewall" "default_egress_deny" {
  name      = "default-egress-deny"
  network   = google_compute_network.this.name
  direction = "EGRESS"
  priority  = 65533
  deny {
    protocol = "all"
  }
}

resource "google_service_account" "ssh" {
  account_id   = "allow-ssh"
  display_name = "allow-ssh"
}

resource "google_compute_firewall" "ssh-ingress" {
  name      = "ssh-ingress"
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
    google_service_account.ssh.email
  ]
}

resource "google_compute_instance" "default" {
  name         = "test"
  machine_type = "f1-micro"
  zone         = var.instance_zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet[local.compute_region].name
  }

  service_account {
    email  = google_service_account.ssh.email
    scopes = ["cloud-platform"]
  }
}
