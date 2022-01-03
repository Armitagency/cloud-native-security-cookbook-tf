variable "organization_domain" {
  type        = string
  description = "The organization domain of your Google Cloud estate"
}

variable "target_folder_id" {
  type        = string
  description = "The folder that requires only VPC connected functions"
}

variable "target_project_id" {
  type        = string
  description = "The project that requires restricted function ingresses"
}
