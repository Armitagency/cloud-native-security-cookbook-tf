resource "google_compute_network" "this" {
  name = "flow-log-example"
}

resource "google_compute_subnetwork" "subnet" {
  name          = "flow-log-subnet"
  ip_cidr_range = "10.0.0.0/24"
  network       = google_compute_network.this.id

  log_config {
    aggregation_interval = "INTERVAL_5_SEC"
    flow_sampling        = 1
    metadata             = "INCLUDE_ALL_METADATA"
  }
}

data "google_organization" "this" {
  domain = var.organization_domain
}

resource "google_organization_iam_audit_config" "organization" {
  org_id  = data.google_organization.this.org_id
  service = "allServices"
  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

resource "google_dns_policy" "logging" {
  name = "logging"

  enable_logging = true

  networks {
    network_url = google_compute_network.this.id
  }
}

resource "google_compute_firewall" "rule" {
  name    = "log-firewall"
  network = google_compute_network.this.name

  deny {
    protocol = "icmp"
  }

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

resource "google_compute_router" "router" {
  name    = "router"
  network = google_compute_network.this.id
}

resource "google_compute_router_nat" "nat" {
  name                               = "logging-nat"
  router                             = google_compute_router.router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ALL"
  }
}
