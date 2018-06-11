# -----------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# -----------------------------------------------------------------------------

variable "name" {
  description = "The name of the load balancer"
  type        = "string"
}

variable "autoscaling_group_id" {
  description = "The autoscaling group that will be attached to the load balancer"
  type        = "string"
}

variable "security_group_ids" {
  description = "The security_group_ids to attach to the load balancer"
  type        = "list"
}

variable "subnet_ids" {
  description = "The subnet_ids to attach to the load balancer"
  type        = "list"
}

variable "dns_domain" {
  description = "The base domain where the load balancer will be exposed"
  type        = "string"
}

variable "dns_name" {
  description = "The full dns name that will resolve to the load balancer"
  type        = "string"
}

# -----------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# -----------------------------------------------------------------------------

variable "internal" {
  description = "Whether or not the load balancer should be internal (private)"
  default     = true
}

variable "listeners" {
  description = "A list of listeners between the load balancer and the instances"
  default     = []
}

variable "health_checks" {
  description = "A list of health_checks to test for the health of the instances"
  default     = []
}
