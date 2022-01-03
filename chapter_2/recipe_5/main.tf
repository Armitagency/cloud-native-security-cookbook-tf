data "aws_organizations_organization" "this" {}

resource "aws_organizations_policy_attachment" "root" {
  policy_id = aws_organizations_policy.top_level_region_lock.id
  target_id = data.aws_organizations_organization.this.roots[0].id
}

resource "aws_organizations_policy" "top_level_region_lock" {
  name     = "region-lock"
  content  = data.aws_iam_policy_document.region_lock_policy.json
}

data "aws_iam_policy_document" "region_lock_policy" {
  statement {
    effect      = "Deny"
    not_actions = local.service_exemptions
    resources   = ["*"]
    condition {
      test     = "StringNotEquals"
      values   = var.allowed_regions
      variable = "aws:RequestedRegion"
    }
  }
}
