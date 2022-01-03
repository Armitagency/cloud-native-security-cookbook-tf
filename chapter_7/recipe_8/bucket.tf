resource "aws_s3_bucket" "test" {
  // checkov:skip=CKV_AWS_144
  bucket = "test"
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "aws:kms"
      }
    }
  }

  versioning {
    enabled = true
  }

  logging {
    target_bucket = "access_logging"
    target_prefix = "log/test"
  }
}

resource "aws_s3_bucket_public_access_block" "test" {
  bucket = aws_s3_bucket.test.id

  block_public_acls       = true
  block_public_policy     = true
  restrict_public_buckets = true
  ignore_public_acls      = true
}
