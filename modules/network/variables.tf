# ------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ------------------------------------------------------------------------------

variable "name" {
  type = "string"
}

variable "vpc_cidr_block" {
  type = "string"
}

variable "availability_zones" {
  type = "list"
}
