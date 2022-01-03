resource "random_password" "database" {
  length           = 16
  special          = true
  override_special = "_%@"
}

resource "aws_db_instance" "default" {
  allocated_storage      = 10
  db_subnet_group_name   = aws_db_subnet_group.default.name
  engine                 = "postgres"
  engine_version         = "13.2"
  instance_class         = "db.t3.micro"
  name                   = "encrypteddatabase"
  kms_key_id             = aws_kms_key.this.arn
  username               = "postgres"
  password               = random_password.database.result
  parameter_group_name   = "default.postgres13"
  skip_final_snapshot    = true
  storage_encrypted      = true
  vpc_security_group_ids = [aws_security_group.database.id]
}

resource "aws_db_subnet_group" "default" {
  subnet_ids = var.database_subnet_ids
}

resource "aws_security_group" "database" {
  vpc_id = var.vpc_id
}

output "database_password" {
  value = aws_db_instance.default.password
}
