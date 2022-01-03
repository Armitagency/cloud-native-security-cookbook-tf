variable "vpc_cidr" {
  type        = string
  description = "The CIDR range for the entire VPC"
}

variable "public_cidrs" {
  type        = list(any)
  description = "A list of CIDRs for the public subnets"
}

variable "private_cidrs" {
  type        = list(any)
  description = "A list of CIDRs for the private subnets"
}

variable "internal_cidrs" {
  type        = list(any)
  description = "A list of CIDRs for the internal subnets"
}

variable "public_key_path" {
  type        = string
  description = "The absolute path to your public key"
}

variable "private_key_path" {
  type        = string
  description = "The absolute path to your private key"
}
