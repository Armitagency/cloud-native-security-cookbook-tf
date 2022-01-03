resource "aws_s3_bucket" "encrypted_bucket" {
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.this.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket" "kms_enforcement" {
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.this.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "kms_enforcement" {
  bucket = aws_s3_bucket.kms_enforcement.id
  policy = data.aws_iam_policy_document.kms_enforcement.json
}

data "aws_iam_policy_document" "kms_enforcement" {
  statement {
    effect = "Deny"

    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.kms_enforcement.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      values   = ["aws:kms"]
      variable = "s3:x-amz-server-side-encryption"
    }
  }
}

resource "aws_s3_bucket" "specific_kms_enforcement" {
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = aws_kms_key.this.arn
        sse_algorithm     = "aws:kms"
      }
    }
  }
}

resource "aws_s3_bucket_policy" "specific_kms_enforcement" {
  bucket = aws_s3_bucket.specific_kms_enforcement.id
  policy = data.aws_iam_policy_document.specific_kms_enforcement.json
}

data "aws_iam_policy_document" "specific_kms_enforcement" {
  statement {
    effect = "Deny"

    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.specific_kms_enforcement.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "StringNotEquals"
      values   = [aws_kms_key.this.arn]
      variable = "s3:x-amz-server-side-encryption-aws-kms-key-id"
    }
  }
}
