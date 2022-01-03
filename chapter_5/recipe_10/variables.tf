variable "project" {
  type        = string
  description = "The project to deploy the resources into"
}

variable "region_subnets" {
  type        = map(any)
  description = "A map of region subnet pairings"
}

variable "application_region" {
  type        = string
  description = "The region to deploy the application"
}

variable "application_zone" {
  type        = string
  description = "The zone to deploy into, e.g. a, b or c"
}

variable "hosted_zone_domain" {
  type        = string
  description = "The name of your hosted zone resource"
}

variable "dns_record" {
  type        = string
  description = "The DNS record for your application"
}
