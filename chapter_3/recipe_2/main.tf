resource "aws_organizations_organization" "this" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "guardduty.amazonaws.com",
    "ram.amazonaws.com",
    "config-multiaccountsetup.amazonaws.com",
    "config.amazonaws.com",
    "member.org.stacksets.cloudformation.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com"
  ]
  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY",
  ]
}

resource "aws_securityhub_organization_admin_account" "this" {
  depends_on = [aws_organizations_organization.this]

  admin_account_id = var.delegated_admin_account
}

resource "aws_securityhub_organization_configuration" "this" {
  auto_enable = true
}
