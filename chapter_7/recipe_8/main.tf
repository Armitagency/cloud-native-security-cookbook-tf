data "aws_caller_identity" "current" {}

data "aws_organizations_organization" "current" {}

resource "aws_organizations_policy" "compliance" {
  name = "compliance_guardrails"

  content = data.aws_iam_policy_document.compliance.json
}

data "aws_iam_policy_document" "compliance" {
  statement {
    effect = "Deny"
    actions = [
      "ec2:DeleteFlowLogs",
      "logs:DeleteLogStream",
      "logs:DeleteLogGroup"
    ]
    resources = [
      "*"
    ]
  }
}

resource "aws_organizations_policy_attachment" "root" {
  policy_id = aws_organizations_policy.compliance.id
  target_id = data.aws_organizations_organization.current.roots[0].id
}
