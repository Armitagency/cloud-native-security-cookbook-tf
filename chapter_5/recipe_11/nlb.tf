resource "aws_lb" "nlb" {
  name               = "network-load-balanced-ecs"
  internal           = false
  load_balancer_type = "network"
  subnets            = [for subnet in aws_subnet.public : subnet.id]
}

resource "aws_lb_listener" "nlb" {
  load_balancer_arn = aws_lb.nlb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.network.arn
  }
}

resource "aws_lb_target_group" "network" {
  port        = 80
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = aws_vpc.this.id
}

output "nlb_url" {
  value = "http://${aws_lb.nlb.dns_name}"
}
