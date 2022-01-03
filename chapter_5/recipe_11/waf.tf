resource "aws_wafv2_web_acl" "firewall" {
  name  = "load-balancer-firewall"
  scope = "REGIONAL"

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
    metric_name                = "base-firewall"
    sampled_requests_enabled   = false
  }
}

resource "aws_wafv2_web_acl_association" "load_balancer" {
  resource_arn = aws_lb.application.arn
  web_acl_arn  = aws_wafv2_web_acl.firewall.arn
}
