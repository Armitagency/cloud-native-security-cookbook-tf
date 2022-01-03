variable "project" {
  type        = string
  description = "The project to deploy the resources into"
}

variable "region_subnets" {
  type        = map(any)
  description = "A map of region subnet pairings"
}
