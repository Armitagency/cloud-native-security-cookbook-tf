variable "central_account" {
  type        = string
  description = "The account ID for the centralised Config account"
}

variable "target_account" {
  type        = string
  description = "The account ID to configure the Delivery Channel in"
}

variable "cross_account_role" {
  type        = string
  description = "The cross account role to assume"
}

variable "bucket_name" {
  type        = string
  description = "The name of the bucket to store AWS Config data"
}
