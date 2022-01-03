resource "aws_s3_bucket" "state" {
  bucket        = "${var.repository_name}-state"
  force_destroy = true

  versioning {
    enabled = true
  }
}

resource "aws_codecommit_repository" "this" {
  repository_name = var.repository_name
  default_branch  = "main"
}

resource "aws_iam_role" "codebuild" {
  name = "${var.repository_name}-codebuild"

  assume_role_policy = data.aws_iam_policy_document.cb_assume.json

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
}

data "aws_iam_policy_document" "cb_assume" {
  statement {
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

resource "aws_codebuild_project" "main" {
  name = "${var.repository_name}-main"

  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "hashicorp/terraform:1.0.0"
    type         = "LINUX_CONTAINER"
  }

  source {
    type     = "CODECOMMIT"
    location = aws_codecommit_repository.this.clone_url_http
  }
}

resource "aws_codebuild_project" "pull_requests" {
  name = "${var.repository_name}-pull-requests"

  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "hashicorp/terraform:1.0.0"
    type         = "LINUX_CONTAINER"
  }

  source {
    type     = "CODECOMMIT"
    location = aws_codecommit_repository.this.clone_url_http
  }
}

resource "aws_cloudwatch_event_rule" "pull_requests" {
  name          = "${var.repository_name}-pull-requests"
  event_pattern = <<PATTERN
{
  "detail": {
    "event": [
      "pullRequestCreated",
      "pullRequestSourceBranchUpdated"
    ]
  },
  "detail-type": ["CodeCommit Pull Request State Change"],
  "resources": ["${aws_codecommit_repository.this.arn}"],
  "source": ["aws.codecommit"]
}
PATTERN
}

resource "aws_cloudwatch_event_rule" "main" {
  name          = "${var.repository_name}-main"
  event_pattern = <<PATTERN
{
  "detail": {
    "event": [
      "referenceUpdated"
    ],
    "referenceName": [
      "${aws_codecommit_repository.this.default_branch}"
    ]
  },
  "detail-type": ["CodeCommit Repository State Change"],
  "resources": ["${aws_codecommit_repository.this.arn}"],
  "source": ["aws.codecommit"]
}
PATTERN
}

resource "aws_cloudwatch_event_target" "main" {
  arn       = aws_codebuild_project.main.arn
  input     = <<TEMPLATE
{
  "sourceVersion": "${aws_codecommit_repository.this.default_branch}"
}
TEMPLATE
  role_arn  = aws_iam_role.events.arn
  rule      = aws_cloudwatch_event_rule.main.name
  target_id = "Main"
}

resource "aws_cloudwatch_event_target" "pull_requests" {
  arn       = aws_codebuild_project.pull_requests.arn
  role_arn  = aws_iam_role.events.arn
  rule      = aws_cloudwatch_event_rule.pull_requests.name
  target_id = "PullRequests"

  input_transformer {
    input_paths = {
      sourceVersion : "$.detail.sourceCommit"
    }

    input_template = <<TEMPLATE
{
  "sourceVersion": <sourceVersion>
}
TEMPLATE
  }
}

resource "aws_iam_role" "events" {
  name = "${var.repository_name}-events"

  assume_role_policy = data.aws_iam_policy_document.events_assume.json

  inline_policy {
    name = "execution"

    policy = data.aws_iam_policy_document.events_execution.json
  }
}

data "aws_iam_policy_document" "events_assume" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"
      identifiers = [
        "events.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "events_execution" {
  statement {
    actions = [
      "codebuild:StartBuild"
    ]

    resources = [
      aws_codebuild_project.main.arn,
      aws_codebuild_project.pull_requests.arn,
    ]
  }
}

resource "aws_cloudwatch_event_target" "checkov" {
  arn       = aws_codebuild_project.checkov.arn
  role_arn  = aws_iam_role.events.arn
  rule      = aws_cloudwatch_event_rule.pull_requests.name
  target_id = "Checkov"

  input_transformer {
    input_paths = {
      sourceVersion : "$.detail.sourceCommit"
    }

    input_template = <<TEMPLATE
{
  "sourceVersion": <sourceVersion>
}
TEMPLATE
  }
}

resource "aws_codebuild_project" "checkov" {
  name = "${var.repository_name}-checkov"

  service_role = aws_iam_role.codebuild.arn

  artifacts {
    type = "NO_ARTIFACTS"
  }

  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "bridgecrew/checkov"
    type         = "LINUX_CONTAINER"
  }

  source {
    type     = "CODECOMMIT"
    location = aws_codecommit_repository.this.clone_url_http
  }
}

output "add_remote_command" {
  value = join("", [
    "git remote add origin ",
    "codecommit://",
    var.profile_name,
    "@",
    aws_codecommit_repository.this.repository_name
  ])
}

output "backend" {
  value = <<BACKEND
  backend "s3" {
    bucket = "${aws_s3_bucket.state.bucket}"
    key    = "terraform.tfstate"
  }
BACKEND
}
