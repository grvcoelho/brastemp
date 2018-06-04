# -----------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# -----------------------------------------------------------------------------

variable "security_group_id" {
  description = "The ID of the security group to which we should add the Consul security group rules"
}

# -----------------------------------------------------------------------------
# OPTIONAL PARAMETERS
# These parameters have reasonable defaults.
# -----------------------------------------------------------------------------

variable "allowed_inbound_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the EC2 Instances will allow connections to Consul"
  type        = "list"
  default     = []
}

variable "allowed_inbound_security_group_ids" {
  description = "A list of security group IDs that will be allowed to connect to Consul"
  type        = "list"
  default     = []
}

variable "http_port" {
  description = "The port used by clients to talk to the HTTP API"
  default     = 4646
}

variable "rpc_port" {
  description = "The port used by servers to handle incoming requests from other agents."
  default     = 4647
}

variable "serf_port" {
  description = "The port used to handle gossip in the LAN. Required by all agents."
  default     = 4648
}
