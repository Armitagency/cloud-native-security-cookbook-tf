resource "aws_ecs_cluster" "this" {
  name = "load_balanced_cluster"
}

resource "aws_ecs_service" "this" {
  name            = "application"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  load_balancer {
    target_group_arn = aws_lb_target_group.application.arn
    container_name   = "nginx"
    container_port   = 80
  }

  network_configuration {
    subnets         = [for subnet in aws_subnet.private : subnet.id]
    security_groups = [aws_security_group.application.id]
  }
}

resource "aws_security_group" "application" {
  name   = "ecs-task-sg"
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "alb_ingress" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.alb.id
  security_group_id        = aws_security_group.application.id
}

resource "aws_security_group_rule" "application_public_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.application.id
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
