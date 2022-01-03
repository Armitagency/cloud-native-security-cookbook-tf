data "aws_organizations_organization" "this" {}

resource "aws_macie2_account" "payer" {}

resource "aws_macie2_organization_admin_account" "this" {
  admin_account_id = var.delegated_admin_account
  depends_on       = [aws_macie2_account.payer]
}

resource "aws_macie2_member" "account" {
  provider   = aws.delegated_admin_account
  for_each   = { for account in data.aws_organizations_organization.this.accounts : account.id => account if account.id != var.delegated_admin_account }
  account_id = each.value.id
  email      = each.value.email
  depends_on = [aws_macie2_organization_admin_account.this]
}
