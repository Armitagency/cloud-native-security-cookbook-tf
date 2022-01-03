variable "delegated_admin_account" {
  type        = string
  description = "The account ID for the account to be the Config delegated admin"
}

variable "cross_account_role" {
  type        = string
  description = "The cross account role to assume"
}
