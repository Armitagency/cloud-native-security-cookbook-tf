variable "project" {
  type        = string
  description = "The ID of the project to deploy the infrastructure"
}

variable "region" {
  type        = string
  description = "The region to deploy the infrastructure in"
}

variable "organization_domain" {
  type        = string
  description = "The domain of your GCP organization"
}
