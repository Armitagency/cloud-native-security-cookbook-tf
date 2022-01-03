variable "key_administrator_role" {
  type        = string
  description = "The role used to administer the key"
}

variable "database_subnets_ids" {
  type        = string
  description = "The IDs of the subnets to host the database"
}
