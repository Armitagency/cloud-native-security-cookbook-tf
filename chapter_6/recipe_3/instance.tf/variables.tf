variable "resource_group_name" {
  type        = string
  description = "The name of the resource group to use"
}

variable "instance_name" {
  type        = string
  description = "The name for the instance"
}

variable "subnet_id" {
  type        = string
  description = "The subnet to place the instance into"
}

variable "ssh_key_path" {
  type        = string
  description = "The path to the SSH key to upload"
}
