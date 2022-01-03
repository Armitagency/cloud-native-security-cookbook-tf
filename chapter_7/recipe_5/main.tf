resource "aws_organizations_organization" "this" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config-multiaccountsetup.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "macie.amazonaws.com",
    "member.org.stacksets.cloudformation.amazonaws.com",
    "ram.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com",
  ]
  enabled_policy_types = ["SERVICE_CONTROL_POLICY", "TAG_POLICY"]
  feature_set          = "ALL"
}

resource "aws_organizations_delegated_administrator" "config-multiaccount" {
  account_id        = var.delegated_admin_account_id
  service_principal = "config-multiaccountsetup.amazonaws.com"
}

resource "aws_organizations_delegated_administrator" "config" {
  account_id        = var.delegated_admin_account_id
  service_principal = "config.amazonaws.com"
}

resource "aws_config_organization_managed_rule" "rule" {
  provider = aws.delegated_admin
  for_each = toset(var.managed_config_rules)

  name            = each.value
  rule_identifier = each.value

  depends_on = [
    aws_organizations_delegated_administrator.config-multiaccount
  ]
}

resource "aws_config_configuration_aggregator" "organization" {
  provider = aws.delegated_admin
  name     = "organization-aggregator"

  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.config_aggregator.arn
  }
}

resource "aws_iam_role" "config_aggregator" {
  provider = aws.delegated_admin
  name     = "config_aggregator"

  assume_role_policy = data.aws_iam_policy_document.assume.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
  ]
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "config.amazonaws.com"
      ]
    }
  }
}
