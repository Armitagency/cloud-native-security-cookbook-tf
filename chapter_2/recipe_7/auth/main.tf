resource "google_project_service" "cloud_identity" {
  service = "cloudidentity.googleapis.com"
}

resource "google_project_service" "admin" {
  service = "admin.googleapis.com"
}

resource "google_service_account" "workspace_admin" {
  account_id   = "workspace-admin2"
  display_name = "Workspace Admin2"
}

resource "google_service_account_key" "workspace_admin" {
  service_account_id = google_service_account.workspace_admin.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "local_file" "workspace_admin" {
  content  = base64decode(google_service_account_key.workspace_admin.private_key)
  filename = "workspace_admin.json"
}
