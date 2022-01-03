variable "production_folder_name" {
  type        = string
  description = "The name of the production folder"
}

variable "nonproduction_folder_name" {
  type        = string
  description = "The name of the nonproduction folder"
}

variable "development_folder_name" {
  type        = string
  description = "The name of the development folder"
}

variable "project_prefix" {
  type        = string
  description = "Used to prefix the project names to ensure global uniqueness"
}

variable "team_name" {
  type        = string
  description = "The name of the team to be onboarded"
}
