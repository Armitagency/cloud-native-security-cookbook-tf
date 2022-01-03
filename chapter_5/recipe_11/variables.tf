variable "vpc_cidr" {
  type = string
}

variable "public_cidrs" {
  type = list(any)
}

variable "private_cidrs" {
  type = list(any)
}

variable "internal_cidrs" {
  type = list(any)
}

variable "region" {
  type = string
}

variable "hosted_zone_domain" {
  type        = string
  description = "The name of your hosted zone domain"
}
