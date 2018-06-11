# -----------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# -----------------------------------------------------------------------------

variable "name" {
  type = "string"
}

variable "autoscaling_group_id" {
  type = "string"
}

variable "security_group_ids" {
  type = "list"
}

variable "subnet_ids" {
  type = "list"
}

# -----------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# -----------------------------------------------------------------------------

variable "internal" {
  default = true
}

variable "listeners" {
  default = []
}

variable "health_checks" {
  default = []
}
