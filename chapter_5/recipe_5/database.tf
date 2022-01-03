resource "random_password" "database" {
  length  = 16
  special = false
}

resource "aws_db_instance" "default" {
  allocated_storage      = 10
  db_subnet_group_name   = aws_db_subnet_group.default.name
  engine                 = "postgres"
  engine_version         = "13.2"
  instance_class         = "db.t3.micro"
  name                   = "mydb"
  username               = "postgres"
  password               = random_password.database.result
  parameter_group_name   = "default.postgres13"
  skip_final_snapshot    = true
  vpc_security_group_ids = [aws_security_group.database.id]
}

resource "aws_security_group_rule" "database_egress" {
  type                     = "egress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.database.id
  security_group_id        = aws_security_group.instance.id
}

resource "aws_db_subnet_group" "default" {
  subnet_ids = [for subnet in aws_subnet.internal : subnet.id]
}

resource "aws_security_group" "database" {
  vpc_id = aws_vpc.this.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.instance.id]
  }
}

output "db_password" {
  value     = random_password.database.result
  sensitive = true
}

output "tunnel_command" {
  value = join(" ", [
    "ssh",
    "-i ${var.private_key_path}",
    "ubuntu@${aws_instance.web.id}",
    "-L",
    "5432:${aws_db_instance.default.address}:5432",
  ])
}
