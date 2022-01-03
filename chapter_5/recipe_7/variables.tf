variable "organization_domain" {
  type        = string
  description = "The domain for your Organization"
}

variable "project" {
  type        = string
  description = "The project to deploy the resources into"
}

variable "region_subnets" {
  type        = map(any)
  description = "A map of region subnet pairings"
}

variable "region" {
  type        = string
  description = "The region to deploy the hub subnet into"
}

variable "hub_project" {
  type        = string
  description = "The project ID for the central hub"
}

variable "service_projects" {
  type        = list(string)
  description = "The projects to have share the VPC"
}
