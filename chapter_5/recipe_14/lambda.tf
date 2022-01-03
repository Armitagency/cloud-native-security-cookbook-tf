resource "aws_iam_role" "iam_for_lambda" {
  provider = aws.consumer
  name     = "iam_for_lambda"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
  ]

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_security_group" "function" {
  provider = aws.consumer
  vpc_id   = aws_vpc.consumer_this.id
}

resource "aws_security_group_rule" "function" {
  provider                 = aws.consumer
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.endpoint.id
  security_group_id        = aws_security_group.function.id
}

resource "aws_security_group_rule" "endpoint" {
  provider                 = aws.consumer
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "TCP"
  source_security_group_id = aws_security_group.function.id
  security_group_id        = aws_security_group.endpoint.id
}

resource "aws_lambda_function" "tester" {
  provider      = aws.consumer
  filename      = data.archive_file.function.output_path
  function_name = "nginx_tester"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "index.handler"

  source_code_hash = filebase64sha256(data.archive_file.function.output_path)

  vpc_config {
    security_group_ids = [
      aws_security_group.function.id
    ]
    subnet_ids = [
      for subnet in aws_subnet.consumer_private : subnet.id
    ]
  }

  runtime = "python3.9"

  depends_on = [
    data.archive_file.function
  ]
}

resource "null_resource" "install_requests" {
  provisioner "local-exec" {
    command = "pip3 install --target ./package requests"
  }
}

resource "local_file" "function" {
  filename = "${path.module}/package/index.py"
  content  = <<CONTENT
from requests import get

def handler(*_):
  print(get("http://${aws_vpc_endpoint.nginx.dns_entry[0]["dns_name"]}"))
CONTENT

  depends_on = [
    null_resource.install_requests
  ]
}

data "archive_file" "function" {
  type        = "zip"
  output_path = "${path.module}/function.zip"

  source_dir = "${path.module}/package"

  depends_on = [
    null_resource.install_requests,
    local_file.function
  ]
}
