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
