resource "google_project_service" "resource_manager" {
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_iam_member" "compute_admin" {
  role = "roles/resourcemanager.projectIamAdmin"

  member = "user:${var.user_email}"

  condition {
    title       = "only_compute_engine"
    description = "Only allows granting compute engine roles"
    expression = join("", [
      "api.getAttribute('iam.googleapis.com/modifiedGrantsByRole', [])",
      ".hasOnly([",
      "'roles/computeAdmin'",
      "])"
    ])
  }

  depends_on = [
    google_project_service.resource_manager
  ]
}
