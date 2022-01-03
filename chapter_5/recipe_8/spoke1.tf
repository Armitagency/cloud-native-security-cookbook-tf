resource "aws_vpc" "spoke1" {
  provider             = aws.spoke1
  cidr_block           = "10.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "spoke1_private" {
  provider          = aws.spoke1
  availability_zone = "eu-west-1a"
  vpc_id            = aws_vpc.spoke1.id
  cidr_block        = aws_vpc.spoke1.cidr_block
}

resource "aws_default_route_table" "spoke1" {
  provider               = aws.spoke1
  default_route_table_id = aws_vpc.spoke1.default_route_table_id

  route {
    cidr_block         = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway.this.id
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "s1" {
  provider           = aws.spoke1
  subnet_ids         = [aws_subnet.spoke1_private.id]
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = aws_vpc.spoke1.id

  depends_on = [
    aws_ram_resource_association.transit_gateway,
    aws_ram_principal_association.org_share
  ]
}
