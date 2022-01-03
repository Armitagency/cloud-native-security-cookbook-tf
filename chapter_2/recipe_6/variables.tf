variable "root_management_group_uuid" {
  type = string
  description = "The UUID for the root management group"
}

variable "allowed_locations" {
  type        = list(string)
  description = "The locations to allow resources"
}
