variable "spoke1_account_id" {
  type        = string
  description = "The Account ID of the first spoke account"
}

variable "spoke2_account_id" {
  type        = string
  description = "The Account ID of the second spoke account"
}

variable "cross_account_role" {
  type        = string
  description = "The role that can be assumed in each spoke"
}

variable "vpn_asn" {
  type        = number
  description = "The ASN you wish the VPN to use"
}

variable "vpn_ip_address" {
  type        = string
  description = "The IP address of the on-premise VPN endpoint"
}
