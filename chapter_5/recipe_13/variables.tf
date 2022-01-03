variable "project" {
  type        = string
  description = "The project to deploy the resources into"
}

variable "region_subnets" {
  type        = map(any)
  description = "A map of region subnet pairings"
}

variable "provider_project" {
  type        = string
  description = "The project to deploy the private workload into"
}

variable "region" {
  type        = string
  description = "The region to deploy the application into"
}

variable "application_subnet" {
  type        = string
  description = "The CIDR range for the application"
}

variable "attachment_subnet" {
  type        = string
  description = "The CIDR range for the service attachment"
}
