# -----------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# -----------------------------------------------------------------------------

variable "nomad_address" {
  description = "The address of an instance of nomad server on the format http://10.10.10.10:4646"
  type        = "string"
}

variable "traefik_domain" {
  description = "Base domain that will be used as main traefik endpoint"
  type        = "string"
}

# -----------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# -----------------------------------------------------------------------------

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
