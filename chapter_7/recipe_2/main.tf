resource "aws_s3_bucket" "pii_bucket" {
  bucket        = var.bucket_name
  force_destroy = true
}
