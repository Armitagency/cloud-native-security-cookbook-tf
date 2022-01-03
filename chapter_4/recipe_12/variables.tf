variable "location" {
  type        = string
  description = "The location to deploy your resource into"
}

variable "purview_account_name" {
  type        = string
  description = "The name for the Purview account"
}

variable "storage_account_name" {
  type        = string
  description = "The name for the storage account"
}

variable "filename" {
  type        = string
  description = "The name of the local file to upload"
}
