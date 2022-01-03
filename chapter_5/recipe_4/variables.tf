variable "project" {
  type        = string
  description = "The project to deploy the resources into"
}

variable "instance_zone" {
  type        = string
  description = "The zone for the Compute Engine instance"
}

variable "region_subnets" {
  type        = map(any)
  description = "A map of region subnet pairings"
}
