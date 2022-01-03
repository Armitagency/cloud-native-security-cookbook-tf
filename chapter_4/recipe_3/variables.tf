variable "location" {
  type        = string
  description = "The location to deploy your resource into"
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account"
}

variable "sensitive_subscription_ids" {
  type        = list(string)
  description = "The IDs of the sensitive data subscriptions"
}
