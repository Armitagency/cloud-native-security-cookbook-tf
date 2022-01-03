variable "project" {
  type        = string
  description = "The project to deploy the resources into"
}

variable "region" {
  type        = string
  description = "The region to deploy the resources into"
}

variable "secondary_zone" {
  type        = string
  description = "The second zone to deploy the resources into"
}

variable "start_time_utc" {
  type        = string
  description = "The snapshot start time in UTC"
}

variable "storage_locations" {
  type        = list(string)
  description = "The locations to store the snapshot"
}

variable "zone" {
  type        = string
  description = "The zone to deploy the resources into"
}
