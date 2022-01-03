resource "aws_vpc_endpoint_service" "nginx" {
  acceptance_required        = false
  network_load_balancer_arns = [aws_lb.nlb.arn]
}

resource "aws_vpc_endpoint_service_allowed_principal" "consumer" {
  vpc_endpoint_service_id = aws_vpc_endpoint_service.nginx.id
  principal_arn           = "arn:aws:iam::${var.consumer_account_id}:root"
}

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

resource "aws_ecs_cluster" "this" {
  name = "load_balanced_cluster"
}

resource "aws_ecs_service" "network" {
  name            = "network"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.network.arn
    container_name   = "nginx"
    container_port   = 80
  }

  network_configuration {
    subnets         = [for subnet in aws_subnet.private : subnet.id]
    security_groups = [aws_security_group.network.id]
  }
}

resource "aws_ecs_task_definition" "this" {
  family = "service"
  cpu    = "256"
  memory = "512"
  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "nginx"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
}

resource "aws_security_group" "network" {
  name   = "nlb-ecs-task-sg"
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "network_public_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.network.id
}

resource "aws_security_group_rule" "nlb_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = aws_security_group.network.id
}
