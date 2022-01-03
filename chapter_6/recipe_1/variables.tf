variable "project" {
  type        = string
  description = "The project to deploy the resources into"
}

variable "region" {
  type        = string
  description = "The region to deploy the resources into"
}

variable "zone" {
  type        = string
  description = "The zone to deploy the resources into"
}

variable "instance_name" {
  type        = string
  description = "The name of the instance"
}
