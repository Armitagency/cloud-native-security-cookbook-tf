resource "aws_lb" "application" {
  name               = "application-load-balanced-ecs"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [for subnet in aws_subnet.public : subnet.id]
}

resource "aws_lb_listener" "application" {
  load_balancer_arn = aws_lb.application.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.nginx.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.application.arn
  }
}

resource "aws_security_group" "alb" {
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "public_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb.id
}

resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.application.id
  security_group_id        = aws_security_group.alb.id
}

resource "aws_lb_target_group" "application" {
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.this.id
}

resource "aws_route53_record" "application" {
  name    = "application.${var.hosted_zone_domain}"
  type    = "A"
  zone_id = data.aws_route53_zone.this.zone_id

  alias {
    name                   = aws_lb.application.dns_name
    zone_id                = aws_lb.application.zone_id
    evaluate_target_health = true
  }
}

data "aws_route53_zone" "this" {
  name = var.hosted_zone_domain
}

resource "aws_acm_certificate" "nginx" {
  domain_name       = "*.${var.hosted_zone_domain}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "certificate_validation" {
  for_each = {
    for dvo in aws_acm_certificate.nginx.domain_validation_options : dvo.domain_name => {
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

output "alb_url" {
  value = "https://${aws_route53_record.application.name}"
}
