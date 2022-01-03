data "google_organization" "current" {
  domain = var.organization_domain
}

resource "google_service_account" "cloud_assets" {
  account_id   = "cloud-assets"
  display_name = "Cloud Assets"
}

resource "google_service_account_key" "cloud_assets" {
  service_account_id = google_service_account.cloud_assets.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "local_file" "cloud_assets" {
  content  = base64decode(google_service_account_key.cloud_assets.private_key)
  filename = "cloud_assets.json"
}

resource "google_organization_iam_member" "cloud_assets" {
  org_id = data.google_organization.current.org_id
  role   = "roles/cloudasset.owner"

  member = "serviceAccount:${google_service_account.cloud_assets.email}"
}

resource "google_project_iam_member" "cloud_assets" {
  for_each = toset(var.target_projects)
  project  = each.value
  role     = "roles/serviceusage.serviceUsageConsumer"

  member = "serviceAccount:${google_service_account.cloud_assets.email}"
}
