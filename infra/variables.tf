# -----------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# -----------------------------------------------------------------------------

variable "dns_domain" {
  description = "The base domain name to be used by DNS records"
  type        = "string"
}

# -----------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# -----------------------------------------------------------------------------

variable "name" {
  description = "The name of the application"
  default     = "brastemp"
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
  description = "The SSH Key pair used to ssh into the created machines"
  default     = "brastemp"
}

variable "cluster_size" {
  description = "The size of the brastemp cluster"
  default     = 3
}

variable "cluster_tag_key" {
  description = "Name of the tag used by consul to auto-join machines into the cluster"
  default     = "consul-servers"
}

variable "cluster_tag_value" {
  description = "Value of the tag used by consul to auto-join machines into the cluster"
  default     = "auto-join"
}

variable "load_balancer_dns_prefix" {
  description = "The prefix of the dns record to be added to the client load balancer"
  default     = "lb"
}
