variable "project" {
  type        = string
  description = "The project to deploy the resources into"
}

variable "region" {
  type        = string
  description = "The region to deploy the resources into"
}

variable "function_name" {
  type        = string
  description = "The name of the function"
}

variable "email_address" {
  type        = string
  description = "The email address to send alerts to"
}
