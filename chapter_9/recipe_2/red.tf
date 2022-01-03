resource "aws_secretsmanager_secret" "red" {
  provider = aws.red
  name = "red"

  tags = {
    "team-name": "red"
  }
}
