data "aws_organizations_organization" "this" {}

resource "aws_config_delivery_channel" "this" {
  provider       = aws.target
  name           = "delivery_channel"
  s3_bucket_name = aws_s3_bucket.central_config.bucket
  sns_topic_arn  = aws_sns_topic.config.arn
  depends_on     = [aws_config_configuration_recorder.this, aws_s3_bucket_policy.config]
}

resource "aws_s3_bucket" "central_config" {
  provider = aws.central
  bucket   = var.bucket_name
}

resource "aws_s3_bucket_policy" "config" {
  provider = aws.central
  bucket = aws_s3_bucket.central_config.id

  policy = data.aws_iam_policy_document.bucket_policy.json
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    actions = [
      "S3:GetBucketAcl",
      "S3:ListBucket",
      "S3:PutObject",
    ]

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.config.arn]
    }

    resources = [
      aws_s3_bucket.central_config.arn,
      "${aws_s3_bucket.central_config.arn}/*"
    ]
  }
}

resource "aws_sns_topic" "config" {
  name = "central_config"
}

resource "aws_sns_topic_policy" "default" {
  arn = aws_sns_topic.config.arn

  policy = data.aws_iam_policy_document.allow_config.json
}

data "aws_iam_policy_document" "allow_config" {
  statement {
    actions = [
      "SNS:Publish"
    ]

    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.config.arn]
    }

    resources = [
      aws_sns_topic.config.arn,
    ]
  }
}

resource "aws_config_configuration_recorder" "this" {
  provider = aws.target
  name     = "recorder"
  role_arn = aws_iam_role.config.arn
}

resource "aws_iam_role" "config" {
  provider = aws.target
  name     = "config-delivery"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "config" {
  provider = aws.target
  name     = "config-delivery"
  role     = aws_iam_role.config.id
  policy   = data.aws_iam_policy_document.config_role.json
}

data "aws_iam_policy_document" "config_role" {
  statement {
    actions = [
      "SNS:Publish"
    ]

    effect = "Allow"

    resources = [
      aws_sns_topic.config.arn,
    ]
  }

  statement {
    actions = [
      "S3:GetBucketAcl",
      "S3:ListBucket",
      "S3:PutObject",
      "S3:PutObjectAcl"
    ]

    effect = "Allow"

    resources = [
      aws_s3_bucket.central_config.arn,
      "${aws_s3_bucket.central_config.arn}/*"
    ]
  }
}
