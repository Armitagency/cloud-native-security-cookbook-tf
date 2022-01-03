variable "delegated_admin_account" {
  type        = string
  description = "The account ID for your GuardDuty delegated administrator"
}

variable "cross_account_role" {
  type        = string
  description = "The name of the role in the delegated administrator account to assume"
}

variable "python_path" {
  type        = string
  description = "Path to python executable that has the boto3 library installed"
}
