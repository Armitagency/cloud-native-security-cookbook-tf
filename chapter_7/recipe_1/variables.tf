variable "project" {
  type        = string
  description = "The project to deploy the resources into"
}

variable "region" {
  type        = string
  description = "The region to deploy the resources into"
}

variable "bucket_name" {
  type        = string
  description = "The name of the bucket"
}

variable "cost_center" {
  type        = string
  description = "The cost center to charge for the bucket"
}

variable "data_classification" {
  type        = string
  description = "The data classification of the bucket"
}
