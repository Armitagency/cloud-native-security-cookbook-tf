data "aws_region" "current" {}

resource "aws_ebs_default_kms_key" "this" {
  key_arn = aws_kms_key.this.arn
}

resource "aws_ebs_encryption_by_default" "this" {
  enabled = true

  depends_on = [
    aws_ebs_default_kms_key.this
  ]
}

resource "aws_ebs_volume" "this" {
  availability_zone = "${data.aws_region.current.name}a"
  size              = 1
  type              = "gp3"
  depends_on = [
    aws_ebs_encryption_by_default.this
  ]
}
