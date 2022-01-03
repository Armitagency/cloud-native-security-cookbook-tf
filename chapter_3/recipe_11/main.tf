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

resource "null_resource" "set_delegated_admin" {
  provisioner "local-exec" {
    command = join(" ",[
      "python",
      "set_delegated_admin.py",
      var.delegated_admin_account
    ])
  }
}

resource "aws_config_configuration_aggregator" "organization" {
  provider = aws.delegated_admin_account
  depends_on = [
    aws_iam_role_policy_attachment.organization,
    null_resource.set_delegated_admin
  ]

  name = "org_aggregator"

  organization_aggregation_source {
    all_regions = true
    role_arn    = aws_iam_role.organization.arn
  }
}

resource "aws_iam_role" "organization" {
  provider = aws.delegated_admin_account

  name = "org-config-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "organization" {
  provider = aws.delegated_admin_account

  role       = aws_iam_role.organization.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSConfigRoleForOrganizations"
}
