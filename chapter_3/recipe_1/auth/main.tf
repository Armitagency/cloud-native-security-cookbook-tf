resource "google_project_service" "scc" {
  service = "securitycenter.googleapis.com"
}

data "google_organization" "this" {
  domain = var.organization_domain
}

resource "google_service_account" "scc_admin" {
  account_id   = "scc-admin"
  display_name = "SCC Admin"
}

resource "google_organization_iam_binding" "scc_admin" {
  role   = "roles/securitycenter.notificationConfigEditor"
  org_id = data.google_organization.this.org_id

  members = [
    "serviceAccount:${google_service_account.scc_admin.email}",
  ]
}

resource "google_service_account_key" "scc_admin" {
  service_account_id = google_service_account.scc_admin.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "local_file" "scc_admin" {
  content  = base64decode(google_service_account_key.scc_admin.private_key)
  filename = "scc_admin.json"
}
