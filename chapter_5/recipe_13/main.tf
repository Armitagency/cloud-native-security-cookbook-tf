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

resource "google_compute_router" "router" {
  for_each = var.region_subnets
  name     = "router-${each.key}"
  network  = google_compute_network.this.id
  region   = each.key
}

resource "google_compute_router_nat" "nat" {
  for_each                           = var.region_subnets
  name                               = "nat-${each.key}"
  router                             = google_compute_router.router[each.key].name
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  region                             = each.key
}

resource "google_compute_route" "internet_route" {
  name             = "internet"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.this.name
  next_hop_gateway = "default-internet-gateway"
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

resource "google_compute_firewall" "internet_egress" {
  name      = "allow-internet-egress"
  network   = google_compute_network.this.name
  direction = "EGRESS"
  priority  = 1000
  allow {
    protocol = "all"
  }

  target_tags = ["external-egress"]
}

resource "google_compute_firewall" "internet_ingress" {
  name      = "allow-internet-ingress"
  network   = google_compute_network.this.name
  direction = "INGRESS"
  priority  = 1000
  allow {
    protocol = "all"
  }

  target_tags = ["external-ingress"]
}
