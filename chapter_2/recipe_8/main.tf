resource "aws_iam_role" "target_read_only" {
  provider = aws.target_account

  assume_role_policy  = data.aws_iam_policy_document.assume_policy.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
}

data "aws_iam_policy_document" "assume_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${var.auth_account_id}:root"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_user" "user" {
  provider = aws.auth_account
  for_each = toset(var.users)

  name          = each.value
  force_destroy = true
}

resource "aws_iam_group" "group" {
  provider = aws.auth_account
  name     = "read_only"
  path     = "/${var.target_account_id}/"
}

resource "aws_iam_group_membership" "group" {
  provider = aws.auth_account
  name     = "${var.target_account_id}_read_only"

  users = [for user in var.users : user]

  group = aws_iam_group.group.name
}

resource "aws_iam_group_policy" "target_read_only" {
  provider = aws.auth_account

  name  = "${var.target_account_id}_read_only"
  group = aws_iam_group.group.name

  policy = data.aws_iam_policy_document.target_read_only.json
}

data "aws_iam_policy_document" "target_read_only" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]

    effect = "Allow"

    resources = [
      aws_iam_role.target_read_only.arn
    ]
  }
}
