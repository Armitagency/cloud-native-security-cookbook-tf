locals {
  rules_to_deploy = [
    "ALB_HTTP_TO_HTTPS_REDIRECTION_CHECK",
    "API_GW_SSL_ENABLED",
    "ELB_TLS_HTTPS_LISTENERS_ONLY",
    "REDSHIFT_REQUIRE_TLS_SSL",
    "RESTRICTED_INCOMING_TRAFFIC",
    "S3_BUCKET_SSL_REQUESTS_ONLY",
    "VPC_SG_OPEN_ONLY_TO_AUTHORIZED_PORTS"
  ]
}

resource "aws_config_config_rule" "rule" {
  for_each = toset(local.rules_to_deploy)
  name = each.value

  source {
    owner = "AWS"
    source_identifier = each.value
  }
}
