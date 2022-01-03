data "aws_organizations_organization" "current" {}

resource "aws_cloudtrail" "organizational_trail" {
  name                          = "organizational_trail"
  s3_bucket_name                = aws_s3_bucket.centralized_audit_logs.id
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = true
  enable_log_file_validation    = true

  depends_on = [
    aws_s3_bucket_policy.cloudtrail_access,
  ]
}

resource "aws_s3_bucket" "centralized_audit_logs" {
  provider      = aws.logging
  bucket        = var.bucket_name
}

resource "aws_s3_bucket_policy" "cloudtrail_access" {
  provider = aws.logging
  bucket = aws_s3_bucket.centralized_audit_logs.id
  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "${aws_s3_bucket.centralized_audit_logs.arn}"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": join("/", [
              aws_s3_bucket.centralized_audit_logs.arn,
              "AWSLogs",
              var.logging_account_id,
              "*"
            ])
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        },
        {
            "Sid": "AWSCloudTrailWriteOrgWrite",
            "Effect": "Allow",
            "Principal": {
                "Service": [
                    "cloudtrail.amazonaws.com"
                ]
            },
            "Action": "s3:PutObject",
            "Resource": join("/", [
              aws_s3_bucket.centralized_audit_logs.arn,
              "AWSLogs",
              data.aws_organizations_organization.current.id,
              "*"
            ])
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}
