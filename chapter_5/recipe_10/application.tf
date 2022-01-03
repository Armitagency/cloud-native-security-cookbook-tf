data "google_dns_managed_zone" "target" {
  name = var.hosted_zone_domain
}

resource "google_dns_record_set" "set" {
  name         = var.dns_record
  type         = "A"
  ttl          = 3600
  managed_zone = data.google_dns_managed_zone.target.name
  rrdatas = [
    google_compute_global_forwarding_rule.default.ip_address
  ]
}

resource "google_compute_managed_ssl_certificate" "prod" {
  name = "production"

  managed {
    domains = [
      var.dns_record
    ]
  }
}

resource "google_compute_global_forwarding_rule" "default" {
  name       = "global-rule"
  target     = google_compute_target_https_proxy.nginx.id
  port_range = "443"
}

resource "google_compute_target_https_proxy" "nginx" {
  name    = "nginx"
  url_map = google_compute_url_map.nginx.id
  ssl_certificates = [
    google_compute_managed_ssl_certificate.prod.id
  ]
}

resource "google_compute_url_map" "nginx" {
  name            = "url-map-target-proxy"
  description     = "a description"
  default_service = google_compute_backend_service.nginx.id

  host_rule {
    hosts        = [var.dns_record]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.nginx.id

    path_rule {
      paths   = ["/*"]
      service = google_compute_backend_service.nginx.id
    }
  }
}

resource "google_service_account" "nginx" {
  account_id   = "nginx-workers"
  display_name = "nginx-workers"
}

resource "google_compute_backend_service" "nginx" {
  name        = "backend"
  port_name   = "http"
  protocol    = "HTTP"
  timeout_sec = 10

  backend {
    group = google_compute_instance_group.nginx.id
  }

  health_checks = [google_compute_http_health_check.nginx.id]
}

resource "google_compute_http_health_check" "nginx" {
  name               = "check-backend"
  request_path       = "/"
  check_interval_sec = 1
  timeout_sec        = 1
}

resource "google_compute_instance_group" "nginx" {
  name = "nginx"

  instances = [
    google_compute_instance.nginx.id,
  ]

  named_port {
    name = "http"
    port = "80"
  }

  zone = "europe-west1-b"
}

resource "google_compute_firewall" "http-ingress" {
  name      = "http-ingress"
  network   = google_compute_network.this.name
  direction = "INGRESS"
  priority  = 1000
  allow {
    protocol = "TCP"
    ports    = ["80"]
  }

  source_ranges = [
    "130.211.0.0/22",
    "35.191.0.0/16"
  ]

  target_service_accounts = [
    google_service_account.nginx.email
  ]
}

resource "google_compute_firewall" "internet_egress" {
  name      = "allow-internet-egress"
  network   = google_compute_network.this.name
  direction = "EGRESS"
  priority  = 1000
  allow {
    protocol = "all"
  }

  target_service_accounts = [
    google_service_account.nginx.email
  ]
}

resource "google_compute_instance" "nginx" {
  name                      = "nginx"
  machine_type              = "f1-micro"
  zone                      = join("-", [
    var.application_region,
    var.application_zone
  ])
  allow_stopping_for_update = true

  boot_disk {
    initialize_params {
      image = "cos-cloud/cos-stable-89-16108-470-25"
    }
  }

  metadata_startup_script = "docker run -p 80:80 nginx"

  network_interface {
    subnetwork = google_compute_subnetwork.subnet[var.application_region].name
  }

  service_account {
    email  = google_service_account.nginx.email
    scopes = ["cloud-platform"]
  }
}
