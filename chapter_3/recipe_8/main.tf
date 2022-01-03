resource "aws_guardduty_organization_admin_account" "this" {
  admin_account_id = var.delegated_admin_account
}

resource "aws_guardduty_organization_configuration" "delegated_admin" {
  provider    = aws.delegated_admin_account
  auto_enable = true
  detector_id = aws_guardduty_detector.delegated_admin.id

  datasources {
    s3_logs {
      auto_enable = true
    }
  }

  depends_on = [
    aws_guardduty_organization_admin_account.this,
  ]
}

resource "aws_guardduty_detector" "delegated_admin" {
  provider = aws.delegated_admin_account
  enable   = true
}
