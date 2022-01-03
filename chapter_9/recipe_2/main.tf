data "aws_caller_identity" "current" {}

resource "aws_iam_role" "red_team" {
  name = "red_team"
  assume_role_policy = data.aws_iam_policy_document.assume_policy.json

  tags = {
    "team-name": "red"
  }
}

data "aws_iam_policy_document" "assume_policy" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type = "AWS"
      identifiers = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_iam_policy" "secrets_management" {
  name = "secrets_management"
  path = "/"
  policy = data.aws_iam_policy_document.secrets_management.json
}

resource "aws_iam_role_policy_attachment" "red_secrets_management" {
  role = aws_iam_role.red_team.name
  policy_arn = aws_iam_policy.secrets_management.arn
}

data "aws_iam_policy_document" "secrets_management" {
  statement {
    effect = "Allow"
    actions = ["secretsmanager:*"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/team-name"
      values = [
        "$${aws:PrincipalTag/team-name}"
      ]
    }

    condition {
      test     = "ForAllValues:StringEquals"
      variable = "aws:TagKeys"
      values = [
        "team-name"
      ]
    }

    condition {
      test     = "StringEqualsIfExists"
      variable = "aws:ResourceTag/team-name"
      values = [
        "$${aws:PrincipalTag/team-name}"
      ]
    }
  }
}
