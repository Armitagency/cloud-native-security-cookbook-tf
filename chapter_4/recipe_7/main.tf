data "google_organization" "current" {
  domain = var.organization_domain
}

data "google_project" "current" {}

resource "google_project_service" "cloud_asset" {
  service = "cloudasset.googleapis.com"
}

resource "null_resource" "cloudasset_service_account" {
  provisioner "local-exec" {
    command = join(" ", [
      "gcloud beta services identity create",
      "--service=cloudasset.googleapis.com",
      "--project=${var.project_id}"
    ])
  }

  depends_on = [
    google_project_service.cloud_asset
  ]
}

resource "google_bigquery_dataset" "assets" {
  dataset_id                 = "assets"
  delete_contents_on_destroy = true
}

resource "google_project_iam_member" "asset_sa_editor_access" {
  role   = "roles/bigquery.dataEditor"
  member = join("",[
    "serviceAccount:service-",
    data.google_project.current.number,
    "@gcp-sa-cloudasset.iam.gserviceaccount.com"
  ])

  depends_on = [
    null_resource.cloudasset_service_account
  ]
}

resource "google_project_iam_member" "asset_sa_user_access" {
  role   = "roles/bigquery.user"
  member = join("",[
    "serviceAccount:service-",
    data.google_project.current.number,
    "@gcp-sa-cloudasset.iam.gserviceaccount.com"
  ])

  depends_on = [
    null_resource.cloudasset_service_account
  ]
}

resource "null_resource" "run_export" {
  provisioner "local-exec" {
    command = join(" ", [
      "gcloud asset export --content-type resource",
      "--project ${data.google_project.current.project_id},
      "--bigquery-table ${google_bigquery_dataset.assets.id}/tables/assets,
      "--output-bigquery-force --per-asset-type"
    ])
  }

  depends_on = [
    google_project_iam_member.asset_sa_editor_access,
    google_project_iam_member.asset_sa_user_access
  ]
}
