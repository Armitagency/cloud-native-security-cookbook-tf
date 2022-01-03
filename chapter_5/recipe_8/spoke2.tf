resource "aws_vpc" "spoke2" {
  provider             = aws.spoke2
  cidr_block           = "10.0.1.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

resource "aws_subnet" "spoke2_private" {
  provider          = aws.spoke2
  availability_zone = "eu-west-1b"
  vpc_id            = aws_vpc.spoke2.id
  cidr_block        = aws_vpc.spoke2.cidr_block
}

resource "aws_default_route_table" "spoke2" {
  provider               = aws.spoke2
  default_route_table_id = aws_vpc.spoke2.default_route_table_id

  route {
    cidr_block         = "10.0.0.0/8"
    transit_gateway_id = aws_ec2_transit_gateway.this.id
  }
}

resource "aws_ec2_transit_gateway_vpc_attachment" "s2" {
  provider           = aws.spoke2
  subnet_ids         = [aws_subnet.spoke2_private.id]
  transit_gateway_id = aws_ec2_transit_gateway.this.id
  vpc_id             = aws_vpc.spoke2.id

  depends_on = [
    aws_ram_resource_association.transit_gateway,
    aws_ram_principal_association.org_share
  ]
}
