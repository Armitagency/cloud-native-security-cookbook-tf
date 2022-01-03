data "google_organization" "this" {
  domain = var.organization_domain
}

data "google_project" "current" {}

resource "null_resource" "create_assets_service_account" {
  provisioner "local-exec" {
    command = join(" ", [
      "gcloud beta services identity create",
      "--service=cloudasset.googleapis.com"
    ])
  }
}

resource "google_project_service" "assets_api" {
  service  = "cloudasset.googleapis.com"
}

resource "google_cloud_asset_organization_feed" "networking_changes" {
  billing_project = data.google_project.current.name
  org_id          = data.google_organization.this.org_id
  feed_id         = "network-changes"
  content_type    = "RESOURCE"

  asset_types = [
    "compute.googleapis.com/Subnetwork",
    "compute.googleapis.com/Network",
    "compute.googleapis.com/Router",
    "compute.googleapis.com/Route",
    "compute.googleapis.com/ExternalVpnGateway"
  ]

  feed_output_config {
    pubsub_destination {
      topic = google_pubsub_topic.network_changes.id
    }
  }

  depends_on = [
    google_pubsub_topic_iam_member.cloud_asset_writer,
    google_project_service.assets_api
  ]
}

resource "google_pubsub_topic" "network_changes" {
  name     = "network-changes"
}

resource "google_pubsub_topic_iam_member" "cloud_asset_writer" {
  topic   = google_pubsub_topic.network_changes.id
  role    = "roles/pubsub.publisher"
  member  = join("",[
    "serviceAccount:service-",
    data.google_project.current.number,
    "@gcp-sa-cloudasset.iam.gserviceaccount.com"
  ])

  depends_on = [
    null_resource.create_assets_service_account
  ]
}
