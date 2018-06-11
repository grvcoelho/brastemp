variable "name" {
  default = "brastemp"
}

variable "aws_profile" {
  description = "The AWS profile to be used by terraform"
  default     = "brastemp"
}

variable "aws_region" {
  description = "The AWS region where resources will be created"
  default     = "us-east-1"
}

variable "ssh_key_name" {
  default = "brastemp"
}

variable "cluster_size" {
  default = 3
}

variable "cluster_tag_key" {
  default = "consul-servers"
}

variable "cluster_tag_value" {
  default = "auto-join"
}
