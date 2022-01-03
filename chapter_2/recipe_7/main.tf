resource "random_password" "password" {
  for_each = var.users
  length   = 16
  special  = true
}

resource "googleworkspace_user" "user" {
  for_each = var.users
  name {
    family_name = each.value.family_name
    given_name  = each.value.given_name
  }
  change_password_at_next_login = true
  password                      = random_password.password[each.key].result
  primary_email                 = each.key
}

resource "googleworkspace_group" "team" {
  email       = var.team_email
  name        = var.team_name
  description = var.team_description
}

resource "googleworkspace_group_member" "team" {
  for_each = var.users
  group_id = googleworkspace_group.team.id
  email    = googleworkspace_user.user[each.key].primary_email
}

resource "google_project_iam_binding" "target_project_access" {
  project = var.target_project_id
  role    = "roles/viewer"
  members = [
    "group:${googleworkspace_group.team.email}",
  ]
}

output "passwords" {
  sensitive = true
  value     = [
    for user in googleworkspace_user.user : {(user.primary_email) = user.password}
  ]
}
