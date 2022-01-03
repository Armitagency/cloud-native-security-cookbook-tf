data "google_project" "current" {}

resource "google_compute_shared_vpc_host_project" "host" {
  project = data.google_project.current.project_id

  depends_on = [
    google_project_service.compute_api
  ]
}

resource "google_compute_shared_vpc_service_project" "service" {
  for_each        = toset(var.service_projects)
  host_project    = google_compute_shared_vpc_host_project.host.project
  service_project = each.value
}
