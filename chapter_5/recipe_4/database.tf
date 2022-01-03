resource "google_project_service" "service_networking" {
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_compute_firewall" "service_account_ingress" {
  name      = join("-", [
    "allow"
    google_service_account.ssh.account_id,
    "to-database-ingress"
  ])
  network   = google_compute_network.this.name
  direction = "INGRESS"
  priority  = 1000
  allow {
    protocol = "TCP"
    ports    = ["5432"]
  }

  source_service_accounts = [google_service_account.ssh.email]

  target_service_accounts = [
    google_sql_database_instance.postgres.service_account_email_address
  ]
}

resource "google_compute_global_address" "private_ip_address" {
  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.this.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
  network                 = google_compute_network.this.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]

  depends_on = [
    google_project_service.service_networking
  ]
}

resource "google_compute_firewall" "service_account_egress" {
  name      = join("-". [
    "allow",
    google_service_account.ssh.account_id,
    "to-database-egress"
  ])
  network   = google_compute_network.this.name
  direction = "EGRESS"
  priority  = 1000
  allow {
    protocol = "TCP"
    ports    = ["5432"]
  }

  destination_ranges = [
    google_sql_database_instance.postgres.private_ip_address
  ]

  target_service_accounts = [google_service_account.ssh.email]
}

resource "google_sql_database_instance" "postgres" {
  name                = "postgres"
  database_version    = "POSTGRES_13"
  deletion_protection = false
  region              = local.compute_region
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.this.id
    }
  }

  depends_on = [
    google_project_service.service_networking,
    google_service_networking_connection.private_vpc_connection
  ]
}

output "tunnel" {
  value = join("", [
    "gcloud compute ssh test ",
    "--ssh-flag '-L 5432:",
    google_sql_database_instance.postgres.private_ip_address,
    ":5432'"
  ])
}
