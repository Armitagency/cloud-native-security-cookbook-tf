resource "aws_config_config_rule" "s3_public" {
  name = "S3_BUCKET_LEVEL_PUBLIC_ACCESS_PROHIBITED"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_LEVEL_PUBLIC_ACCESS_PROHIBITED"
  }
}

resource "aws_config_remediation_configuration" "s3_public" {
  config_rule_name = aws_config_config_rule.s3_public.name
  target_type      = "SSM_DOCUMENT"
  target_id        = "AWSConfigRemediation-ConfigureS3BucketPublicAccessBlock"

  parameter {
    name         = "AutomationAssumeRole"
    static_value = aws_iam_role.remediator.arn
  }

  parameter {
    name           = "BucketName"
    resource_value = "RESOURCE_ID"
  }
}

resource "null_resource" "turn_on_auto_remediate" {
  provisioner "local-exec" {
    command = "python main.py ${aws_config_config_rule.s3_public.name}"
  }

  depends_on = [
    aws_config_remediation_configuration.s3_public
  ]
}

resource "aws_iam_role" "remediator" {
  name = "s3_public_bucket_remediator"

  assume_role_policy = data.aws_iam_policy_document.assume.json
  managed_policy_arns = [
    aws_iam_policy.s3_public_bucket_remediator.arn
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
        "ssm.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_policy" "s3_public_bucket_remediator" {
  name   = "s3_public_bucket_remediator"
  policy = data.aws_iam_policy_document.remediation.json
}

data "aws_iam_policy_document" "remediation" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetBucketPublicAccessBlock",
      "s3:PutBucketPublicAccessBlock"
    ]
    resources = ["*"]
  }
}
