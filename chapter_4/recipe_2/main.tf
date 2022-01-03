resource "aws_kms_key" "key" {
  policy = data.aws_iam_policy_document.key_policy.json
}

data "aws_iam_policy_document" "key_policy" {
  statement {
    sid = "Allow access for Key Administrators"
    actions = [
      "kms:Create*",
      "kms:Describe*",
      "kms:Enable*",
      "kms:List*",
      "kms:Put*",
      "kms:Update*",
      "kms:Revoke*",
      "kms:Disable*",
      "kms:Get*",
      "kms:Delete*",
      "kms:TagResource",
      "kms:UntagResource",
      "kms:ScheduleKeyDeletion",
      "kms:CancelKeyDeletion"
    ]
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [var.key_administrator_role]
    }
    resources = ["*"]
  }

  statement {
    sid = "Allow use of the key"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["*"]
  }

  statement {
    sid    = "Allow attachment of persistent resources"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    actions = [
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = ["*"]
    condition {
      test     = "Bool"
      variable = "kms:GrantIsForAWSResource"
      values   = [true]
    }
  }
}
