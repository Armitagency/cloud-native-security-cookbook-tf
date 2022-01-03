resource "aws_iam_role" "codebuild_service_role" {
  name = "codebuild_service_role"

  assume_role_policy = data.aws_iam_policy_document.assume.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  ]
  inline_policy {
    name = "s3access"
    policy = data.aws_iam_policy_document.s3.json
  }
}

data "aws_iam_policy_document" "assume" {
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "codebuild.amazonaws.com"
      ]
    }
  }
}

resource "aws_codebuild_project" "zap" {
  name         = "owasp-zap"
  service_role = aws_iam_role.codebuild_service_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "owasp/zap2docker-stable"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    buildspec = <<BUILDSPEC
version: 0.2

phases:
  build:
    commands:
      - zap-baseline.py -t ${var.target_url} -I
BUILDSPEC
    type      = "NO_SOURCE"
  }
}

resource "aws_codebuild_project" "zap2" {
  name         = "owasp-zap2"
  service_role = aws_iam_role.codebuild_service_role.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/standard:1.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = true
  }

  source {
    buildspec = <<BUILDSPEC
version: 0.2

phases:
  build:
    commands:
      - ${join(" ", [
        "docker run -v $${PWD}:/zap/wrk owasp/zap2docker-stable",
        "zap-baseline.py -t",
        var.target_url,
        "-I -x report_xml"
      ])}
      - ${join(" ", [
        "aws s3api put-object --bucket",
        aws_s3_bucket.reports.bucket,
        "--key report.xml --body report_xml"
      ])}
BUILDSPEC
    type      = "NO_SOURCE"
  }
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "s3" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = [
      aws_s3_bucket.reports.arn
    ]
  }
}

resource "aws_s3_bucket" "reports" {
  bucket = "${data.aws_caller_identity.current.account_id}-reports"
}
