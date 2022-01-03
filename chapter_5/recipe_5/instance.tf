resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.eu-west-1.ssm"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for subnet in aws_subnet.private : subnet.id]

  security_group_ids = [
    aws_security_group.endpoint_sg.id,
  ]
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.eu-west-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for subnet in aws_subnet.private : subnet.id]

  security_group_ids = [
    aws_security_group.endpoint_sg.id,
  ]
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = aws_vpc.this.id
  service_name        = "com.amazonaws.eu-west-1.ec2messages"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = [for subnet in aws_subnet.private : subnet.id]

  security_group_ids = [
    aws_security_group.endpoint_sg.id,
  ]
}

resource "aws_security_group" "endpoint_sg" {
  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.this.cidr_block]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "local_file" "ssh_public" {
  filename = var.public_key_path
}

resource "aws_key_pair" "key" {
  public_key = data.local_file.ssh_public.content
}

resource "aws_instance" "web" {
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = "t3.micro"
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name
  key_name             = aws_key_pair.key.key_name
  security_groups      = [aws_security_group.instance.id]
  subnet_id            = aws_subnet.private[0].id
}

resource "aws_security_group" "instance" {
  vpc_id = aws_vpc.this.id
}

resource "aws_security_group_rule" "ssh_ingress" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.endpoint_sg.id
  security_group_id        = aws_security_group.instance.id
}

resource "aws_security_group_rule" "endpoint_egress" {
  type                     = "egress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.endpoint_sg.id
  security_group_id        = aws_security_group.instance.id
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "ssm_profile"
  role = aws_iam_role.role.name
}

resource "aws_iam_role" "role" {
  name = "ssm_role"
  path = "/"

  managed_policy_arns = ["arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"]

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}

output "instance_id" {
  value = aws_instance.web.id
}
