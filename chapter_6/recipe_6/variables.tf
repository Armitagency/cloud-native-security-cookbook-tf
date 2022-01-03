variable "location" {
  type        = string
  description = "The Azure location for resources"
}

variable "function_name" {
  type        = string
  description = "The name for the Azure function"
}

variable "email" {
  type        = string
  description = "The email address to notify on errors"
}
