resource "aws_s3_bucket" "bucket" {
  force_destroy = true
}

output "bucket_name" {
  value = aws_s3_bucket.bucket.bucket
}
