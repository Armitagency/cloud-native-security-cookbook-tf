data "aws_region" "current" {}

locals {
  availability_zones = ["a", "b", "c", "d", "e", "f"]
}

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "public" {
  count = length(var.public_cidrs)
  availability_zone = join("", [
    data.aws_region.current.name,
    local.availability_zones[count.index]
  ])
  vpc_id     = aws_vpc.this.id
  cidr_block = var.public_cidrs[count.index]
}

resource "aws_subnet" "private" {
  count = length(var.private_cidrs)
  availability_zone = join("", [
    data.aws_region.current.name,
    local.availability_zones[count.index]
  ])
  vpc_id     = aws_vpc.this.id
  cidr_block = var.private_cidrs[count.index]
}

resource "aws_subnet" "internal" {
  count = length(var.internal_cidrs)
  availability_zone = join("", [
    data.aws_region.current.name,
    local.availability_zones[count.index]
  ])
  vpc_id     = aws_vpc.this.id
  cidr_block = var.internal_cidrs[count.index]
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id
}

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = [for subnet in aws_subnet.public : subnet.id]
}

resource "aws_network_acl_rule" "public_ingress" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 200
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "public_egress" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 200
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "local_private_egress" {
  count          = length(var.private_cidrs)
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100 + count.index
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.private_cidrs[count.index]
}

resource "aws_network_acl_rule" "local_private_ingress" {
  count          = length(var.private_cidrs)
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100 + count.index
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.private_cidrs[count.index]
}

resource "aws_network_acl_rule" "block_private_network_egress" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 150
  egress         = true
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "10.0.0.0/8"
}

resource "aws_network_acl_rule" "block_private_network_ingress" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 150
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "10.0.0.0/8"
}

resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = [for subnet in aws_subnet.private : subnet.id]
}

resource "aws_network_acl_rule" "private_network_ingress" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 150
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl_rule" "private_network_egress" {
  network_acl_id = aws_network_acl.private.id
  rule_number    = 150
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl" "internal" {
  vpc_id     = aws_vpc.this.id
  subnet_ids = [for subnet in aws_subnet.internal : subnet.id]
}

resource "aws_network_acl_rule" "internal_network_ingress" {
  count          = length(var.private_cidrs)
  network_acl_id = aws_network_acl.internal.id
  rule_number    = 90 + count.index
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.private_cidrs[count.index]
}

resource "aws_network_acl_rule" "internal_network_egress" {
  count          = length(var.private_cidrs)
  network_acl_id = aws_network_acl.internal.id
  rule_number    = 90 + count.index
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.private_cidrs[count.index]
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.this.id
}

resource "aws_eip" "nat" {}

resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
}

resource "aws_default_route_table" "this" {
  default_route_table_id = aws_vpc.this.default_route_table_id

  route = []
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gw.id
  route_table_id         = aws_route_table.public.id
}

resource "aws_route_table_association" "public" {
  count          = length(var.public_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id
}

resource "aws_route" "private" {
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.gw.id
  route_table_id         = aws_route_table.private.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table" "internal" {
  vpc_id = aws_vpc.this.id

  route = []
}

resource "aws_route_table_association" "internal" {
  count          = length(var.internal_cidrs)
  subnet_id      = aws_subnet.internal[count.index].id
  route_table_id = aws_route_table.internal.id
}

output "public_subnets" {
  value = [for subnet in aws_subnet.public : subnet.id]
}

output "private_subnets" {
  value = [for subnet in aws_subnet.private : subnet.id]
}

output "internal_subnets" {
  value = [for subnet in aws_subnet.internal : subnet.id]
}
