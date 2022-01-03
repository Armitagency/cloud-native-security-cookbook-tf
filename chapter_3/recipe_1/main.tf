data "google_organization" "this" {
  domain = var.organization_domain
}

resource "null_resource" "create_notification_config" {
  provisioner "local-exec" {
    command = join(" ", [
      var.python_path,
      "main.py",
      data.google_organization.this.org_id,
      var.project_id,
      google_pubsub_topic.scc.id
    ])
  }
}

resource "google_pubsub_topic" "scc" {
  name = "scc-findings"
}

resource "google_pubsub_subscription" "scc" {
  name  = "scc-findings"
  topic = google_pubsub_topic.scc.name
}

resource "google_pubsub_topic_iam_binding" "scc-admin" {
  project = google_pubsub_topic.scc.project
  topic   = google_pubsub_topic.scc.name
  role    = "roles/pubsub.admin"
  members = [
    "serviceAccount:scc-admin@${var.project_id}.iam.gserviceaccount.com",
  ]
}

resource "google_project_service" "cloudfunctions" {
  service = "cloudfunctions.googleapis.com"
}

resource "google_project_service" "cloudbuild" {
  service = "cloudbuild.googleapis.com"
}

resource "google_storage_bucket" "bucket" {
  name = "${split(".", var.organization_domain)[0]}-scc-notifications"
}

data "archive_file" "code" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/main.zip"
}

resource "google_storage_bucket_object" "code" {
  name   = "index.zip"
  bucket = google_storage_bucket.bucket.name
  source = data.archive_file.code.output_path
}

resource "google_cloudfunctions_function" "function" {
  name    = "scc"
  runtime = "python39"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.code.name
  entry_point           = "handle"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.scc.name
  }

  depends_on = [
    google_project_service.cloudfunctions,
    google_project_service.cloudbuild
  ]
}
