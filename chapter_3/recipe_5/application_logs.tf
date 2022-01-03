data "aws_caller_identity" "c" {}

data "aws_organizations_organization" "current" {}

resource "aws_s3_bucket" "centralized_application_logs" {
  force_destroy = true
}

resource "aws_iam_role" "kinesis_firehose_role" {
  assume_role_policy = <<POLICY
{
  "Statement":
    {
      "Effect": "Allow",
      "Principal":
        {
          "Service": "firehose.amazonaws.com"
        },
      "Action": "sts:AssumeRole",
      "Condition":
        {
          "StringEquals": {
            "sts:ExternalId": ${data.aws_caller_identity.c.account_id}
          }
        }
    }
}
POLICY
}

resource "aws_kinesis_firehose_delivery_stream" "log_delivery_stream" {
  name = "log_delivery_stream"
  destination = "s3"

  s3_configuration {
    role_arn   = aws_iam_role.kinesis_firehose_role.arn
    bucket_arn = aws_s3_bucket.centralized_application_logs.arn
  }
}

resource "aws_iam_role" "cloudwatch_logs_role" {
  assume_role_policy = <<POLICY
{
  "Statement": {
    "Effect": "Allow",
    "Principal": { "Service": "logs.amazonaws.com" },
    "Action": "sts:AssumeRole"
  }
}
POLICY

  inline_policy {
    policy = <<POLICY
{
    "Statement":[
      {
        "Effect":"Allow",
        "Action":["firehose:*"],
        "Resource":[
          "arn:aws:firehose:region:${data.aws_caller_identity.c.account_id}:*"
        ]
      }
    ]
}
POLICY
  }
}

resource "aws_cloudwatch_log_destination" "kinesis_firehose" {
  name       = "firehose_destination"
  role_arn   = aws_iam_role.cloudwatch_logs_role.arn
  target_arn = aws_kinesis_firehose_delivery_stream.log_delivery_stream.arn
}

resource "aws_cloudwatch_log_destination_policy" "policy" {
  for_each = toset(data.aws_organizations_organization.current.accounts[*].id)
  destination_name = aws_cloudwatch_log_destination.kinesis_firehose.name
  access_policy    = <<POLICY
{
  "Version" : "2012-10-17",
  "Statement" : [
    {
      "Sid" : "",
      "Effect" : "Allow",
      "Principal" : {
        "AWS" : "${each.value}"
      },
      "Action" : "logs:PutSubscriptionFilter",
      "Resource" : "${aws_cloudwatch_log_destination.kinesis_firehose.arn}"
    }
  ]
}
POLICY
}
