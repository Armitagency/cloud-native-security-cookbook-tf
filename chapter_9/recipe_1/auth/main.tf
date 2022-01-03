resource "google_service_account" "red_team" {
  account_id   = "red-team"
  display_name = "Red Team"
}

resource "google_service_account_key" "red_team" {
  service_account_id = google_service_account.red_team.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "local_file" "red_team" {
  content  = base64decode(google_service_account_key.red_team.private_key)
  filename = "red_team.json"
}

resource "google_service_account" "blue_team" {
  account_id   = "blue-team"
  display_name = "Blue Team"
}

resource "google_service_account_key" "blue_team" {
  service_account_id = google_service_account.blue_team.name
  public_key_type    = "TYPE_X509_PEM_FILE"
}

resource "local_file" "blue_team" {
  content  = base64decode(google_service_account_key.blue_team.private_key)
  filename = "blue_team.json"
}

resource "google_project_iam_member" "red_secrets" {
  role = "roles/secretmanager.admin"

  member = "serviceAccount:${google_service_account.red_team.email}"

  condition {
    title      = "requires_red_team_name"
    expression = "resource.name.endsWith('_red')"
  }
}

resource "google_project_iam_member" "blue_secrets" {
  role = "roles/secretmanager.admin"

  member = "serviceAccount:${google_service_account.blue_team.email}"

  condition {
    title      = "requires_blue_team_name"
    expression = "resource.name.endsWith('_blue')"
  }
}
