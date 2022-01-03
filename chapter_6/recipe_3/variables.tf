variable "location" {
  type        = string
  description = "The Azure location for resources"
}

variable "instance_name" {
  type        = string
  description = "The name for the instance"
}

variable "ssh_key_path" {
  type        = string
  description = "The path to the SSH key to upload"
}
