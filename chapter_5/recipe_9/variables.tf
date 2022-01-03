variable "location" {
  type        = string
  description = "The Azure location for resources"
}

variable "vnet_cidr" {
  type        = string
  description = "The CIDR range for the Virtual Network"
}

variable "public_cidr" {
  type        = string
  description = "The CIDR range for the Public Subnet"
}


variable "private_cidr" {
  type        = string
  description = "The CIDR range for the Private Subnet"
}

variable "internal_cidr" {
  type        = string
  description = "The CIDR range for the Internal Subnet"
}

variable "firewall_cidr" {
  type        = string
  description = "The CIDR range for the Firewall Subnet"
}

variable "hub_subscription_id" {
  type        = string
  description = "The subscription for the Hub Network"
}

variable "hub_cidr" {
  type        = string
  description = "The CIDR range for the Hub Network"
}
