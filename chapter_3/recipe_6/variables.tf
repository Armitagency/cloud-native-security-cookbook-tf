variable "location" {
  type        = string
  description = "The location to create the resources in"
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account"
}

variable "delivery_subscription_id" {
  type        = string
  description = "The delivery team subscription ID"
}

variable "central_subscription_id" {
  type        = string
  description = "The centralised team subscription ID"
}
