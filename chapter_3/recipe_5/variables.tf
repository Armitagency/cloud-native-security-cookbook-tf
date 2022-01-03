variable "logging_account_id" {
  type        = string
  description = "The account ID to deploy resources into"
}

variable "cross_account_role" {
  type        = string
  description = "The name of the role that is assumable in the logging account"
}

variable "bucket_name" {
  type        = string
  description = "The name of the centralized storage bucket"
}
