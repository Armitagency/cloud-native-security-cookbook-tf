resource "aws_organizations_policy" "prevent_config_access" {
  name    = "prevent_config_access"
  content = data.aws_iam_policy_document.prevent_config_access.json
}

data "aws_iam_policy_document" "prevent_config_access" {
  statement {
    sid = "PreventConfigAccess"
    action = [
      "config:*"
    ]
    effect = "Deny"
    resources = [
      "*"
    ]

    condition {
      test     = "StringNotLike"
      variable = "aws:PrincipalARN"
      values = [
        "arn:aws:iam::*:role/${var.role_name}"
      ]
    }
  }
}

resource "aws_organizations_policy_attachment" "account" {
  policy_id = aws_organizations_policy.prevent_config_access.id
  target_id = var.target_id
}
