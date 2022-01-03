resource "aws_organizations_organizational_unit" "team" {
  name      = var.team_name
  parent_id = var.organizational_unit_parent_id
}

resource "aws_organizations_account" "production" {
  name      = "${var.team_name}-production"
  email     = var.production_account_email
  parent_id = aws_organizations_organizational_unit.team.id
}

resource "aws_organizations_account" "preproduction" {
  name      = "${var.team_name}-preproduction"
  email     = var.preproduction_account_email
  parent_id = aws_organizations_organizational_unit.team.id
}

resource "aws_organizations_account" "development" {
  name      = "${var.team_name}-development"
  email     = var.development_account_email
  parent_id = aws_organizations_organizational_unit.team.id
}

resource "aws_organizations_account" "shared" {
  name      = "${var.team_name}-shared"
  email     = var.shared_account_email
  parent_id = aws_organizations_organizational_unit.team.id
}
