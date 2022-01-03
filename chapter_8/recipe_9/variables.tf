variable "tag_key" {
  type        = string
  description = "The tag key to use for machine selection"
}

variable "tag_values" {
  type        = list(string)
  description = "The tag values to use for machine selection"
}

variable "time_zone" {
  type        = string
  description = "The time zone to use for running updates"
}

variable "update_time" {
  type        = string
  description = "The time to run updates"
}
