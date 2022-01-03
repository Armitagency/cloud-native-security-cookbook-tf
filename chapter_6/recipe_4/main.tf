locals {
  required_apis = [
    "cloudbuild.googleapis.com",
    "clouderrorreporting.googleapis.com",
    "cloudfunctions.googleapis.com",
    "logging.googleapis.com",
    "storage.googleapis.com",
  ]
}

resource "google_project_service" "api" {
  for_each           = toset(local.required_apis)
  service            = each.value
  disable_on_destroy = false
}

resource "google_storage_bucket" "bucket" {
  name     = "${var.function_name}-artifacts"
  location = var.region
}

data "archive_file" "code" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/main.zip"
}

resource "google_storage_bucket_object" "code" {
  name   = "${data.archive_file.code.output_md5}.zip"
  bucket = google_storage_bucket.bucket.name
  source = data.archive_file.code.output_path
}

resource "google_cloudfunctions_function" "function" {
  name    = var.function_name
  runtime = "python39"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.code.name
  entry_point           = "handle"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.trigger.name
  }

  depends_on = [
    google_project_service.api
  ]
}

resource "google_project_iam_member" "log_writer" {
  project = var.project
  role    = "roles/logging.logWriter"
  member = join(":", [
    "serviceAccount",
    google_cloudfunctions_function.function.service_account_email
  ])
}

resource "google_cloud_scheduler_job" "daily" {
  name     = var.function_name
  schedule = "* 9 * * *"

  pubsub_target {
    topic_name = google_pubsub_topic.trigger.id
  }
}

resource "google_pubsub_topic" "trigger" {
  name = var.function_name
}

resource "google_monitoring_alert_policy" "errors" {
  display_name = "${var.function_name} Errors"
  combiner     = "OR"
  conditions {
    display_name = "Errors"
    condition_threshold {
      filter = join("", [
        "resource.type = \"cloud_function\" AND ",
        "resource.labels.function_name = \"",
        var.function_name,
        "\" AND ",
        "metric.type = \"logging.googleapis.com/log_entry_count\" AND ",
        "metric.labels.severity = \"ERROR\""
        ]
      )
      duration   = "0s"
      comparison = "COMPARISON_GT"
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_COUNT"
      }
      trigger {
        count = 1
      }
    }
  }

  notification_channels = [
    google_monitoring_notification_channel.email.id
  ]
}

resource "google_monitoring_notification_channel" "email" {
  display_name = "${var.function_name} Error Emails"
  type         = "email"
  labels = {
    email_address = var.email
  }
}
