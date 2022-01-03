data "google_projects" "all_active" {
  filter = "lifecycleState:ACTIVE"
}

data "google_projects" "under_folder" {
  filter = "parent.id:${var.folder_id}"
}

locals {
  required_apis = [
    "logging.googleapis.com",
    "storage.googleapis.com",
  ]
  serverless_apis = [
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
  ]
  all_project_ids = [
    for project in data.google_projects.all_active.projects :
    project.project_id
  ]
  required = setproduct(
    local.required_apis,
    local.all_project_ids
  )
  folder_project_ids = [
    for project in data.google_projects.under_folder.projects :
    project.project_id
  ]
  serverless = setproduct(
    local.serverless_apis,
    local.folder_project_ids
  )
}

resource "google_project_service" "all" {
  for_each           = {
    for req in local.required : index(local.required, req) => req
  }
  service            = each.value[0]
  project            = each.value[1]
  disable_on_destroy = false
}

resource "google_project_service" "serverless" {
  for_each           = {
    for req in local.serverless : index(local.serverless, req) => req
  }
  service            = each.value[0]
  project            = each.value[1]
  disable_on_destroy = false
}
