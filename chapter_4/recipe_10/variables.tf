variable "project_id" {
  type        = string
  description = "The project to create the resources in"
}

variable "region" {
  type        = string
  description = "The region to create the resources in"
}

variable "bucket_path" {
  type        = string
  description = "The bucket path to inspect with DLP"
}
