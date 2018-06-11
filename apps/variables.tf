# -----------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# -----------------------------------------------------------------------------

variable "nomad_address" {
  description = "The address of an instance of nomad server on the format http://10.10.10.10:4646"
  type        = "string"
}

variable "dns_domain" {
  description = "The base domain that will be used to expose services"
  type        = "string"
}

# -----------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# -----------------------------------------------------------------------------

variable "aws_profile" {
  description = "The AWS profile to be used by terraform"
  default     = "brastemp"
}

variable "aws_region" {
  description = "The AWS region where resources will be created"
  default     = "us-east-1"
}

variable "load_balancer_dns_name" {
  description = "REMOVE"
  default     = "brastemp-client-lb-1483179972.us-east-1.elb.amazonaws.com"
}

variable "nomad_region" {
  default = "global"
}

variable "datacenter" {
  default = "dc1"
}

variable "traefik_tag" {
  description = "Tag that will determine whether to register a service with traefik or not"
  default     = "external"
}
