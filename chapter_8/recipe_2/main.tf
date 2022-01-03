data "aws_caller_identity" "current" {}

locals {
  all_roles = join("", [
    "arn:aws:iam::",
    data.aws_caller_identity.current.account_id,
    ":role/*"
  ])
  all_users = join("", [
    "arn:aws:iam::",
    data.aws_caller_identity.current.account_id,
    ":user/*"
  ])
  policy_arn = join("", [
    "arn:aws:iam::",
    data.aws_caller_identity.current.account_id,
    ":policy/",
    local.policy_name
  ])
  policy_name = "general_permissions_boundary"
}

resource "aws_iam_policy" "permissions_boundary" {
  name        = local.policy_name
  path        = "/"
  description = "General Permission Boundary for Principals"

  policy = data.aws_iam_policy_document.permissions_boundary.json
}

data "aws_iam_policy_document" "permissions_boundary" {
  statement {
    sid       = "AllowFullAccess"
    actions   = ["*"]
    effect    = "Allow"
    resources = ["*"]
  }

  statement {
    sid = "DenyCostAndBillingAccess"
    actions = [
      "account:*",
      "aws-portal:*",
      "savingsplans:*",
      "cur:*",
      "ce:*"
    ]
    effect    = "Deny"
    resources = ["*"]
  }

  statement {
    sid = "DenyEditAccessThisPolicy"
    actions = [
      "iam:DeletePolicy",
      "iam:DeletePolicyVersion",
      "iam:CreatePolicyVersion",
      "iam:SetDefaultPolicyVersion"
    ]
    effect = "Deny"
    resources = [
      local.policy_arn
    ]
  }

  statement {
    sid = "DenyRemovalOfPermissionBoundary"
    actions = [
      "iam:DeleteUserPermissionsBoundary",
      "iam:DeleteRolePermissionsBoundary"
    ]
    effect = "Deny"
    resources = [
      local.all_users,
      local.all_roles
    ]

    condition {
      test     = "StringEquals"
      variable = "iam:PermissionsBoundary"
      values = [
        local.policy_arn
      ]
    }
  }

  statement {
    sid = "DenyPrincipalCRUDWithoutPermissionBoundary"
    actions = [
      "iam:PutUserPermissionsBoundary",
      "iam:PutRolePermissionsBoundary",
      "iam:CreateUser",
      "iam:CreateRole"
    ]
    effect = "Deny"
    resources = [
      local.all_users,
      local.all_roles
    ]

    condition {
      test     = "StringNotEquals"
      variable = "iam:PermissionsBoundary"
      values = [
        local.policy_arn
      ]
    }
  }
}

resource "aws_iam_role" "example" {
  name = "permissions_boundary_example"

  assume_role_policy = data.aws_iam_policy_document.assume.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AdministratorAccess"
  ]
  permissions_boundary = aws_iam_policy.permissions_boundary.arn
}

data "aws_iam_policy_document" "assume" {
  statement {
    effect = "Allow"

    principals {
      type = "AWS"
      identifiers = [
        join("", [
          "arn:aws:iam::",
          data.aws_caller_identity.current.account_id,
          ":root"
        ])
      ]
    }

    actions = ["sts:AssumeRole"]
  }
}
