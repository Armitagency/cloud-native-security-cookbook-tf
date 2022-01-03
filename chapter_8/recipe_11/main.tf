data "aws_region" "current" {}

resource "aws_backup_vault" "this" {
  name = "backups"
}

resource "aws_backup_plan" "weekly" {
  name = "weekly"

  rule {
    rule_name         = "Weekly"
    target_vault_name = aws_backup_vault.this.name
    schedule          = "cron(0 12 ? * MON *)"

    lifecycle {
      cold_storage_after = "30"
      delete_after       = "365"
    }

    copy_action {
      destination_vault_arn = aws_backup_vault.central.arn
      lifecycle {
        cold_storage_after = "1"
      }
    }
  }

  rule {
    rule_name                = "WeeklyContinuous"
    target_vault_name        = aws_backup_vault.this.name
    schedule                 = "cron(0 12 ? * MON *)"
    enable_continuous_backup = true

    lifecycle {
      delete_after = "35"
    }
  }

  advanced_backup_setting {
    backup_options = {
      WindowsVSS = "enabled"
    }
    resource_type = "EC2"
  }
}

resource "aws_backup_region_settings" "test" {
  resource_type_opt_in_preference = {
    "Aurora"          = true
    "DocumentDB"      = true
    "DynamoDB"        = true
    "EBS"             = true
    "EC2"             = true
    "EFS"             = true
    "FSx"             = true
    "Neptune"         = true
    "RDS"             = true
    "Storage Gateway" = true
  }
}

resource "aws_backup_selection" "weekly" {
  iam_role_arn = aws_iam_role.backups.arn
  name         = "weekly"
  plan_id      = aws_backup_plan.weekly.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "backup"
    value = "weekly"
  }
}

resource "aws_iam_role" "backups" {
  name               = "backups"
  assume_role_policy = data.aws_iam_policy_document.assume.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  ]
}

data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

data "aws_organizations_organization" "current" {}

resource "aws_backup_vault" "central" {
  name = "central"
}

resource "aws_backup_vault_policy" "org" {
  backup_vault_name = aws_backup_vault.central.name

  policy = data.aws_iam_policy_document.vault.json
}

data "aws_iam_policy_document" "vault" {
  statement {
    actions = ["backup:CopyIntoBackupVault"]
    principals {
      type = "AWS"
      identifiers = ["*"]
    }
    resources = ["*"]

    condition {
      test = "StringEquals"
      values = [
        data.aws_organizations_organization.current.id
      ]
      variable = "aws:PrincipalOrgID"
    }
  }
}
