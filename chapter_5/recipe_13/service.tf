resource "google_compute_service_attachment" "nginx" {
  provider = google.provider
  name     = "nginx"
  region   = var.region

  enable_proxy_protocol = true
  connection_preference = "ACCEPT_AUTOMATIC"
  nat_subnets           = [google_compute_subnetwork.nat.id]
  target_service        = google_compute_forwarding_rule.nginx.id
}

resource "google_compute_forwarding_rule" "nginx" {
  provider = google.provider
  name     = "producer-forwarding-rule"
  region   = var.region

  load_balancing_scheme = "INTERNAL"
  backend_service       = google_compute_region_backend_service.nginx.id
  all_ports             = true
  network               = google_compute_network.provider.name
  subnetwork            = google_compute_subnetwork.nginx.name
}

resource "google_compute_region_backend_service" "nginx" {
  provider    = google.provider
  name        = "nginx"
  protocol    = "TCP"
  timeout_sec = 10
  region      = var.region

  backend {
    group = google_compute_instance_group.nginx.id
  }

  health_checks = [google_compute_health_check.nginx.id]
}

resource "google_compute_instance_group" "nginx" {
  provider = google.provider
  name     = "nginx"

  instances = [
    google_compute_instance.nginx.id,
  ]

  named_port {
    name = "http"
    port = "80"
  }

  zone = "europe-west1-b"
}

resource "google_compute_health_check" "nginx" {
  provider = google.provider
  name     = "nginx"

  check_interval_sec = 1
  timeout_sec        = 1
  tcp_health_check {
    port = "80"
  }
}

resource "google_compute_instance" "nginx" {
  provider                  = google.provider
  name                      = "nginx"
  machine_type              = "f1-micro"
  zone                      = "europe-west1-b"
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable-89-16108-470-25"
    }
  }

  metadata_startup_script = "docker run -p 80:80 nginx"

  network_interface {
    subnetwork = google_compute_subnetwork.nginx.name
  }

  service_account {
    email  = google_service_account.nginx.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_network" "provider" {
  provider                        = google.provider
  name                            = "provider"
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "nginx" {
  provider = google.provider
  name     = "nginx"
  region   = var.region

  network       = google_compute_network.provider.id
  ip_cidr_range = var.application_subnet
}

resource "google_compute_subnetwork" "nat" {
  provider = google.provider
  name     = "nat"
  region   = var.region

  network       = google_compute_network.provider.id
  purpose       = "PRIVATE_SERVICE_CONNECT"
  ip_cidr_range = var.attachment_subnet
}

resource "google_service_account" "nginx" {
  provider     = google.provider
  account_id   = "nginx-workers"
  display_name = "nginx-workers"
}

resource "google_compute_firewall" "http-provider" {
  provider  = google.provider
  name      = "http-ingress"
  network   = google_compute_network.provider.name
  direction = "INGRESS"
  priority  = 1000
  allow {
    protocol = "TCP"
    ports    = ["80"]
  }

  source_ranges = [
    google_compute_subnetwork.nat.ip_cidr_range
  ]

  target_service_accounts = [
    google_service_account.nginx.email
  ]
}

resource "google_compute_address" "service_attachment" {
  name         = "service-attachment"
  address_type = "INTERNAL"
  subnetwork   = google_compute_subnetwork.subnet[var.region].id
  region       = var.region
}

resource "null_resource" "create_forwarding_rule" {
  provisioner "local-exec" {
    command = join(" ", [
      "gcloud compute forwarding-rules create nginx-service",
      "--region ${var.region}",
      "--network ${google_compute_network.this.id}",
      "--address ${google_compute_address.service_attachment.name}",
      "--target-service-attachment ${google_compute_service_attachment.nginx.id}",
      "--project ${var.project}"
    ])
  }
}

output "ip_address" {
  value = google_compute_address.service_attachment.address
}
