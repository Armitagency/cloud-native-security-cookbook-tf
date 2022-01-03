data "google_project" "current" {}

locals {
  required_apis = [
    "websecurityscanner.googleapis.com",
    "appengine.googleapis.com"
  ]
}

resource "google_project_service" "api" {
  for_each           = toset(local.required_apis)
  service            = each.value
  disable_on_destroy = false
}

resource "google_app_engine_application" "app" {
  project     = data.google_project.current.project_id
  location_id = var.location

  depends_on = [
    google_project_service.api
  ]
}

resource "local_file" "app_yaml" {
  filename = "app.yaml"
  content  = <<FILE
runtime: python39

instance_class: F2

handlers:
  - url: '/(.*)'
    secure: always
    static_files: index.html
    upload: index.html
FILE
}

resource "local_file" "index_html" {
  filename = "index.html"
  content  = <<FILE
<html>
  <body>
    <h1>Welcome to your App Engine application.</h1>
  </body>
</html>
FILE
}

resource "null_resource" "deploy_app" {
  provisioner "local-exec" {
    command = "gcloud app deploy --project ${var.project}"
  }

  depends_on = [
    google_app_engine_application.app,
    local_file.app_yaml,
    local_file.index_html
  ]
}

resource "google_security_scanner_scan_config" "app" {
  provider         = google-beta
  display_name     = "app-engine-scan"
  starting_urls    = [
    "https://${google_app_engine_application.app.default_hostname}"
  ]
  target_platforms = ["APP_ENGINE"]
}

resource "null_resource" "run_scan" {
  provisioner "local-exec" {
    command = join(" ", [
      "gcloud alpha web-security-scanner scan-runs start",
      google_security_scanner_scan_config.app.id
    ])
  }
}
