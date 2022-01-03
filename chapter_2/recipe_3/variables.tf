variable "management_group_parent_id" {
  type        = string
  description = "The ID of the parent for the team's management group"
}

variable "billing_account_name" {
  type        = string
  description = "The name of the Azure billing account"
}

variable "enrollment_account_name" {
  type        = string
  description = "The name of the Azure enrollment account"
}

variable "team_name" {
  type        = string
  description = "The name of the team to be onboarded"
}
