resource "google_project_service" "secrets_manager" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

resource "google_secret_manager_secret" "secret-basic" {
  secret_id = "secret_red"

  replication {
    automatic = true
  }

  depends_on = [
    google_project_service.secrets_manager
  ]
}

data "google_secret_manager_secret" "secret" {
  provider = google.red_team
  secret_id = google_secret_manager_secret.secret-basic.secret_id
}
