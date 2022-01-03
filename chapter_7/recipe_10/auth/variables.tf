variable "project" {
  type        = string
  description = "The project to deploy the resources into"
}

variable "organization_domain" {
  type        = string
  description = "The organization domain of your Google Cloud estate"
}

variable "target_projects" {
  type        = list(string)
  description = "The project to enable the remediator for"
}
