variable "project" {
  type        = string
  description = "The project to deploy the resources into"
}

variable "customer_id" {
  type        = string
  description = <<DESCRIPTION
Customer ID for your Google Workspace account
Can be found at https://admin.google.com/ac/accountsettings
DESCRIPTION
}

variable "organization_domain" {
  type        = string
  description = "The domain of your organization"
}

variable "user_email" {
  type        = string
  description = "The email of the user to give IAM admin"
}
