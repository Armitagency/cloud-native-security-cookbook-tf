variable "cross_account_role" {
  type        = string
  description = "The cross account role to assume"
}

variable "delegated_admin_account_id" {
  type        = string
  description = "The account ID to configure as the delegated admin"
}

variable "managed_config_rules" {
  type        = list(string)
  description = "The config rules to apply in all accounts"
}
