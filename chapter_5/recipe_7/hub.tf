resource "google_project_service" "hub_compute_api" {
  provider           = google.hub
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_compute_network" "hub" {
  provider                        = google.hub
  name                            = "network"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true

  depends_on = [
    google_project_service.hub_compute_api,
  ]
}

resource "google_compute_subnetwork" "hub_subnet" {
  provider      = google.hub
  name          = var.region
  ip_cidr_range = "10.0.255.0/24"
  network       = google_compute_network.hub.id
}

resource "google_compute_router" "hub_router" {
  provider = google.hub
  name     = "router"
  network  = google_compute_network.hub.id
}

resource "google_compute_router_nat" "hub_nat" {
  provider                           = google.hub
  name                               = "nat"
  router                             = google_compute_router.hub_router.name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}

resource "google_compute_firewall" "hub_ingress_deny" {
  provider  = google.hub
  name      = "default-ingress-deny"
  network   = google_compute_network.hub.name
  direction = "INGRESS"
  priority  = 65533
  deny {
    protocol = "all"
  }
}

resource "google_compute_firewall" "hub_egress_deny" {
  provider  = google.hub
  name      = "default-egress-deny"
  network   = google_compute_network.hub.name
  direction = "EGRESS"
  priority  = 65533
  deny {
    protocol = "all"
  }
}

resource "google_compute_network_peering" "hub_to_base" {
  name         = "hub-to-base"
  network      = google_compute_network.this.id
  peer_network = google_compute_network.hub.id
}

resource "google_compute_network_peering" "base_to_hub" {
  name         = "base-to-hub"
  network      = google_compute_network.hub.id
  peer_network = google_compute_network.this.id
}

resource "google_compute_ha_vpn_gateway" "on-premise" {
  provider = google.hub
  name     = "on-premise"
  network  = google_compute_network.hub.id
}
