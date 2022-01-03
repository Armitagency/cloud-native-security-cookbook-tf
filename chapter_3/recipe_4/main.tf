data "google_organization" "this" {
  domain = var.organization_domain
}

resource "google_bigquery_dataset" "organization_audit_logs" {
  dataset_id = "organization_audit_logs"
}

resource "google_logging_organization_sink" "organization_sink" {
  name             = "organization_audit"
  org_id           = data.google_organization.this.org_id
  include_children = true
  filter           = "logName:cloudaudit.googleapis.com"

  destination = join("",[
    "bigquery.googleapis.com/",
    google_bigquery_dataset.organization_audit_logs.id
  ])
}

resource "google_bigquery_dataset_access" "access" {
  dataset_id    = google_bigquery_dataset.organization_audit_logs.dataset_id
  role          = "OWNER"
  user_by_email = split(
    ":",
    google_logging_organization_sink.organization_sink.writer_identity
  )[1]
}
