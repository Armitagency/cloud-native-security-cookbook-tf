data "aws_organizations_organization" "current" {}

resource "aws_ec2_transit_gateway" "this" {
  provider = aws.transit
}

resource "aws_ram_resource_share" "transit_gateway" {
  provider = aws.transit
  name     = "transit_gateway"
}

resource "aws_ram_resource_association" "transit_gateway" {
  provider           = aws.transit
  resource_arn       = aws_ec2_transit_gateway.this.arn
  resource_share_arn = aws_ram_resource_share.transit_gateway.arn
}

resource "aws_ram_principal_association" "org_share" {
  provider           = aws.transit
  principal          = data.aws_organizations_organization.current.arn
  resource_share_arn = aws_ram_resource_share.transit_gateway.arn
}

resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "spoke1" {
  provider                      = aws.transit
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.s1.id
}

resource "aws_ec2_transit_gateway_vpc_attachment_accepter" "spoke2" {
  provider                      = aws.transit
  transit_gateway_attachment_id = aws_ec2_transit_gateway_vpc_attachment.s2.id
}

resource "aws_customer_gateway" "this" {
  provider   = aws.transit
  bgp_asn    = var.vpn_asn
  ip_address = var.vpn_ip_address
  type       = "ipsec.1"
}

resource "aws_vpn_connection" "this" {
  provider            = aws.transit
  customer_gateway_id = aws_customer_gateway.this.id
  transit_gateway_id  = aws_ec2_transit_gateway.this.id
  type                = aws_customer_gateway.this.type
}
