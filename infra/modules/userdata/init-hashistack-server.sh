#!/bin/bash

# ------------------------------------------------------------------------------
# LOGGING
# ------------------------------------------------------------------------------

function log {
  local readonly level="$1"
  local readonly message="$2"
  local readonly timestamp=$(date +"%Y-%m-%d %H:%M:%S")
  local readonly script_name="$(basename "$0")"
  >&2 echo -e "$timestamp [$level] [$script_name] $message"
}

function log_info {
  local readonly message="$1"
  log "INFO" "$message"
}

function log_warn {
  local readonly message="$1"
  log "WARN" "$message"
}

function log_error {
  local readonly message="$1"
  log "ERROR" "$message"
}

# ------------------------------------------------------------------------------
# METADATA
# ------------------------------------------------------------------------------

function build_ec2_metadata {
  local readonly metadata_nosce_file="$1"

  cat << EOF > $metadata_nosce_file
EC2_LOCAL_IPV4=$(nosce --endpoint https://169254.now.sh get local-ipv4)"
EC2_PUBLIC_IPV4=$(nosce --endpoint https://169254.now.sh get public-ipv4)"
EC2_INSTANCE_ID=$(nosce --endpoint https://169254.now.sh get instance-id)"
EC2_AVAILABILITY_ZONE=$(nosce --endpoint https://169254.now.sh get availability-zone)"
EOF
}

function build_consul_metadata {
  local readonly consul_nosce_file="$1"

  cat << EOF > $consul_nosce_file
echo "CONSUL_TAG_KEY=${cluster_tag_key}"
echo "CONSUL_TAG_VALUE=${cluster_tag_value}"
EOF
}

# ------------------------------------------------------------------------------
# RUN
# ------------------------------------------------------------------------------

function run {
  local readonly metadata_nosce_file="/etc/nosce/metadata"
  local readonly consul_nosce_file="/etc/nosce/consul"

  log_info "Building EC2 Metadata"
  build_ec2_metadata $metadata_nosce_file

  log_info "Building Consul Metadata"
  build_consul_metadata $consul_nosce_file
}

run "$@"
