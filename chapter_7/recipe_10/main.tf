data "google_project" "current" {}

locals {
  required_apis = [
    "cloudasset.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "storage.googleapis.com",
  ]
}

resource "null_resource" "create_assets_service_account" {
  for_each = toset(var.target_projects)
  provisioner "local-exec" {
    command = join(" ", [
      "gcloud beta services identity create",
      "--service=cloudasset.googleapis.com",
      "--project=${each.value}"
    ])
  }
}

resource "google_project_service" "api" {
  for_each           = toset(local.required_apis)
  service            = each.value
  disable_on_destroy = false
}

resource "google_project_service" "assets" {
  for_each           = toset(var.target_projects)
  project            = each.value
  service            = "cloudasset.googleapis.com"
  disable_on_destroy = false
}

resource "google_cloud_asset_project_feed" "bucket_changes" {
  provider = google.cloud_assets
  for_each     = toset(var.target_projects)
  project      = each.value
  feed_id      = "bucket-changes"
  content_type = "RESOURCE"

  asset_types = [
    "storage.googleapis.com/Bucket",
  ]

  feed_output_config {
    pubsub_destination {
      topic = google_pubsub_topic.bucket_changes.id
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
    google_project_service.api,
    google_project_service.assets,
  ]
}

resource "google_pubsub_topic" "bucket_changes" {
  name = "bucket-changes"
}

data "google_project" "targets" {
  for_each = toset(var.target_projects)
  project_id = each.value
}

resource "google_pubsub_topic_iam_member" "cloud_asset_writer" {
  for_each = toset(var.target_projects)
  topic  = google_pubsub_topic.bucket_changes.id
  role   = "roles/pubsub.publisher"
  member = join("", [
    "serviceAccount:service-",
    data.google_project.targets[each.value].number,
    "@gcp-sa-cloudasset.iam.gserviceaccount.com"
  ])

  depends_on = [
    null_resource.create_assets_service_account
  ]
}

resource "google_storage_bucket" "bucket" {
  name = "${split(".", var.organization_domain)[0]}-bucket-remediator"
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
  name    = "public-bucket-remediation"
  runtime = "python39"

  available_memory_mb   = 128
  source_archive_bucket = google_storage_bucket.bucket.name
  source_archive_object = google_storage_bucket_object.code.name
  entry_point           = "handle"

  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = google_pubsub_topic.bucket_changes.id

    failure_policy {
      retry = false
    }
  }

  depends_on = [
    google_project_service.api
  ]
}

resource "google_project_iam_member" "function" {
  for_each = toset(var.target_projects)
  project  = each.value
  role     = google_project_iam_custom_role.bucket-remediator[each.key].id
  member   = join("", [
    "serviceAccount:",
    google_cloudfunctions_function.function.service_account_email
  ])
}

resource "google_project_iam_custom_role" "bucket-remediator" {
  for_each = toset(var.target_projects)
  project  = each.value
  role_id  = "bucketRemediator"
  title    = "Role used to remediate noncompliant bucket configurations"
  permissions = [
    "storage.buckets.get",
    "storage.buckets.setIamPolicy",
    "storage.buckets.update"
  ]
}
