data "google_projects" "active" {
  filter = "lifecycleState:ACTIVE"
}

locals {
  projects = toset([
    for project in data.google_projects.active.projects : project.project_id
  ])
}

resource "google_bigquery_dataset" "oal" {
  dataset_id = "organization_application_logs"
}

resource "google_logging_project_sink" "project_sink" {
  for_each               = local.projects
  name                   = "${each.value}_application_logs"
  project                = each.value
  unique_writer_identity = true
  exclusions {
    name   = "no_audit_logs"
    filter = "logName:cloudaudit.googleapis.com"
  }

  destination = join("",[
    "bigquery.googleapis.com/",
    google_bigquery_dataset.oal.id
  ])
}

resource "google_bigquery_dataset_access" "project_access" {
  for_each      = local.projects
  dataset_id    = google_bigquery_dataset.oal.dataset_id
  role          = "OWNER"
  user_by_email = split(
    ":",
    google_logging_project_sink.project_sink[each.value].writer_identity
  )[1]
}
