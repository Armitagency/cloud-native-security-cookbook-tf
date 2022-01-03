data "aws_caller_identity" "current" {}

data "aws_route53_zone" "this" {
  name = var.hosted_zone_domain
}

locals {
  alias = "static.${var.hosted_zone_domain}"
}

resource "aws_s3_bucket" "static-website" {
  bucket = "static-website-${data.aws_caller_identity.current.account_id}"
  acl    = "private"
}

resource "aws_s3_bucket_policy" "oai" {
  bucket = aws_s3_bucket.static-website.id
  policy = data.aws_iam_policy_document.oai.json
}

data "aws_iam_policy_document" "oai" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.this.iam_arn]
    }

    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.static-website.arn}/*"]
  }
}

resource "aws_s3_bucket_object" "index" {
  bucket       = aws_s3_bucket.static-website.bucket
  content_type = "text/html"
  key          = "index.html"
  content      = <<CONTENT
<html>
<body>
Static site
</body>
</html>
CONTENT
}

locals {
  s3_origin_id = aws_s3_bucket.static-website.bucket
}

resource "aws_acm_certificate" "cloudfront" {
  provider          = aws.us-east-1
  domain_name       = local.alias
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cloudfront_cert_validation" {
  provider = aws.us-east-1
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.this.zone_id
}

resource "aws_cloudfront_distribution" "static-website" {
  provider = aws.us-east-1
  origin {
    domain_name = aws_s3_bucket.static-website.bucket_regional_domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.this.cloudfront_access_identity_path
    }
  }

  aliases = [local.alias]

  enabled             = true
  default_root_object = "index.html"

  web_acl_id = aws_wafv2_web_acl.global-firewall.arn

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = aws_acm_certificate.cloudfront.arn
    ssl_support_method             = "sni-only"
  }
}

resource "aws_cloudfront_origin_access_identity" "this" {}

resource "aws_route53_record" "static-website" {
  for_each = aws_cloudfront_distribution.static-website.aliases
  name     = each.value
  type     = "A"
  zone_id  = data.aws_route53_zone.this.zone_id

  alias {
    name                   = aws_cloudfront_distribution.static-website.domain_name
    zone_id                = aws_cloudfront_distribution.static-website.hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_wafv2_web_acl" "global-firewall" {
  provider = aws.us-east-1
  name     = "global-firewall"
  scope    = "CLOUDFRONT"

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      count {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "AWSManagedRulesAdminProtectionRuleSet"
      sampled_requests_enabled   = false
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "global-firewall"
    sampled_requests_enabled   = false
  }
}

output "cloudfront_url" {
  value = "https://${local.alias}"
}
