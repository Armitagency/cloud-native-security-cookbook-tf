variable "project" {
  type        = string
  description = "The project to deploy the resources into"
}

variable "time_zone" {
  type        = string
  description = "The IANA timezone to use for the schedule"
}

variable "time_of_day" {
  type = object({
    hours   = number
    minutes = number
    seconds = number
  })
  description = "The time of day to run patching"
}

variable "week_ordinal" {
  type        = number
  description = "The week of the month to run patching"
}

variable "day_of_week" {
  type        = string
  description = "The day of the week to run patching"
}

variable "disruption_budget" {
  type        = number
  description = "The max percentage of machines to disrupt with patching"
}
