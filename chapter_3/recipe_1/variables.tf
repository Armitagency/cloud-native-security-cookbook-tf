variable "project_id" {
  type        = string
  description = "The project to create the resources in"
}

variable "region" {
  type        = string
  description = "The region to create the resources in"
}

variable "organization_domain" {
  type        = string
  description = "The organization domain of your Google Cloud estate"
}

variable "python_path" {
  type        = string
  description = "Path to a python instance that has the required libraries installed"
  default     = "python"
}
