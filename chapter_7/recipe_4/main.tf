data "google_organization" "this" {
  domain = var.organization_domain
}

data "google_project" "current" {}

locals {
  required_apis = [
    "cloudasset.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "secretmanager.googleapis.com"
  ]
}

resource "null_resource" "create_assets_service_account" {
  provisioner "local-exec" {
    command = join(" ", [
      "gcloud beta services identity create",
      "--service=cloudasset.googleapis.com"
    ])
  }
}

resource "google_project_service" "api" {
  for_each = toset(local.required_apis)
  service  = each.value
}

resource "google_cloud_asset_organization_feed" "networking_changes" {
  provider        = google.cloud_assets
  billing_project = data.google_project.current.name
  org_id          = data.google_organization.this.org_id
  feed_id         = "network-changes"
  content_type    = "RESOURCE"

  asset_types = [
    "compute.googleapis.com/Network",
  ]

  feed_output_config {
    pubsub_destination {
      topic = google_pubsub_topic.network_changes.id
    }
  }

  condition {
    expression  = <<EXP
    !temporal_asset.deleted
    EXP
    title       = "created_or_updated"
    description = "Notify on create or update"
  }

  depends_on = [
    google_pubsub_topic_iam_member.cloud_asset_writer,
    google_project_service.api
  ]
}

resource "google_pubsub_topic" "network_changes" {
  name = "network-changes"
}

resource "google_pubsub_topic_iam_member" "cloud_asset_writer" {
  topic  = google_pubsub_topic.network_changes.id
  role   = "roles/pubsub.publisher"
  member = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-cloudasset.iam.gserviceaccount.com"

  depends_on = [
    null_resource.create_assets_service_account
  ]
}

resource "google_storage_bucket" "bucket" {
  name = "${split(".", var.organization_domain)[0]}-asset-notifications"
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
  name    = "asset-change-notifier"
  runtime = "python39"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.code.name
  entry_point           = "handle"

  environment_variables = {
    "CHANNEL"   = var.channel
    "SECRET_ID" = google_secret_manager_secret.slack_token.secret_id
  }

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.network_changes.id

    failure_policy {
      retry = false
    }
  }

  depends_on = [
    google_project_service.api
  ]
}

resource "google_secret_manager_secret" "slack_token" {
  secret_id = "slack-token"

  replication {
    automatic = true
  }

  depends_on = [
    google_project_service.api
  ]
}

resource "google_secret_manager_secret_iam_member" "function" {
  secret_id = google_secret_manager_secret.slack_token.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_cloudfunctions_function.function.service_account_email}"
}

output "update_secret_command" {
  value = join(" ", [
    "echo -n TOKEN |",
    "gcloud secrets versions add",
    google_secret_manager_secret.slack_token.secret_id,
    "--data-file=-"
  ])
}
