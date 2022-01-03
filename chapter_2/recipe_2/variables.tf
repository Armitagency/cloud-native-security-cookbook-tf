variable "production_ou_id" {
  type        = string
  description = "The ID of the production OU"
}

variable "preproduction_ou_id" {
  type        = string
  description = "The ID of the preproduction OU"
}

variable "development_ou_id" {
  type        = string
  description = "The ID of the development OU"
}

variable "team_name" {
  type        = string
  description = "The name of the team to be onboarded"
}

variable "production_account_email" {
  type        = string
  description = "The production root account email"
}

variable "preproduction_account_email" {
  type        = string
  description = "The preproduction root account email"
}

variable "development_account_email" {
  type        = string
  description = "The development root account email"
}

variable "shared_account_email" {
  type        = string
  description = "The shared root account email"
}
