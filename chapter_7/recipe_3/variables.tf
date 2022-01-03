variable "location" {
  type        = string
  description = "The location to deploy the resources into"
}

variable "storage_account_name" {
  type        = string
  description = "The name of the storage account"
}

variable "cost_center" {
  type        = string
  description = "The cost center to charge for the bucket"
}

variable "data_classification" {
  type        = string
  description = "The data classification of the bucket"
}
