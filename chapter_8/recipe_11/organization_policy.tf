resource "aws_organizations_policy" "daily_backups" {
  name    = "daily_backups"
  type    = "BACKUP_POLICY"
  content = <<CONTENT
{
  "plans": {
    "daily": {
      "regions": {
        "@@assign": [
          "${data.aws_region.current.name}"
        ]
      },
      "rules": {
        "daily": {
          "schedule_expression": { "@@assign": "cron(0 9 * * ? *)" },
          "target_backup_vault_name": { "@@assign": "backups" }
        }
      },
      "selections": {
        "tags": {
          "datatype": {
            "iam_role_arn": { "@@assign": "arn:aws:iam::$account:role/backups" },
            "tag_key": { "@@assign": "backup" },
            "tag_value": { "@@assign": [ "daily" ] }
          }
        }
      }
    }
  }
}
CONTENT
}

resource "aws_organizations_policy_attachment" "root" {
  policy_id = aws_organizations_policy.daily_backups.id
  target_id = data.aws_organizations_organization.current.roots[0].id
}
