variable "repository_name" {
  type        = string
  description = "The name for the repository"
}

variable "profile_name" {
  type        = string
  description = "The name of the AWS profile to use for codecommit auth"
  default     = "default"
}
