variable "target_account_id" {
  type = string
  description = "The account to give the users access to"
}

variable "auth_account_id" {
  type = string
  description = "The account to create the users in"
}

variable "cross_account_role" {
  type = string
  description = "The name of the role to use to create the resources in the target and auth accounts"
}

variable "users" {
  type = list(string)
  description = "A list of user email addresses"
}
