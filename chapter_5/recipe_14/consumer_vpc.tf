resource "aws_vpc" "consumer_this" {
  provider             = aws.consumer
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "consumer_private" {
  provider = aws.consumer
  count    = length(var.private_cidrs)
  availability_zone = join("", [
    data.aws_region.current.name,
    local.availability_zones[count.index]
  ])
  vpc_id     = aws_vpc.consumer_this.id
  cidr_block = var.private_cidrs[count.index]
}

resource "aws_default_security_group" "consumer_default" {
  provider = aws.consumer
  vpc_id   = aws_vpc.consumer_this.id
}

resource "aws_security_group" "endpoint" {
  provider = aws.consumer
  vpc_id   = aws_vpc.consumer_this.id
}

resource "aws_vpc_endpoint" "nginx" {
  provider            = aws.consumer
  vpc_id              = aws_vpc.consumer_this.id
  service_name        = aws_vpc_endpoint_service.nginx.service_name
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = false

  security_group_ids = [
    aws_security_group.endpoint.id
  ]

  subnet_ids = [
    for subnet in aws_subnet.consumer_private : subnet.id
  ]

  depends_on = [
    aws_vpc_endpoint_service_allowed_principal.consumer
  ]
}
