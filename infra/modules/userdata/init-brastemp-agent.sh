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
EC2_LOCAL_IPV4=$(nosce get local-ipv4)
EC2_PUBLIC_IPV4=$(nosce get public-ipv4)
EC2_INSTANCE_ID=$(nosce get instance-id)
EC2_AVAILABILITY_ZONE=$(nosce get availability-zone)
EOF

  export $(cat $metadata_nosce_file)
}

function build_consul_metadata {
  local readonly consul_nosce_file="$1"

  cat << EOF > $consul_nosce_file
CONSUL_TAG_KEY=${cluster_tag_key}
CONSUL_TAG_VALUE=${cluster_tag_value}
EOF

  export $(cat $consul_nosce_file)
}

# ------------------------------------------------------------------------------
# CONFIGURATION
# ------------------------------------------------------------------------------

function build_consul_configuration {
  local readonly consul_config_dir="$1"
  local readonly instance_ip_address="$EC2_LOCAL_IPV4"
  local readonly instance_id="$EC2_INSTANCE_ID"
  local readonly datacenter="${datacenter}"
  local readonly region="${region}"
  local filename="client"
  local server="false"
  local bootstrap_expect=""
  local ui="false"

  if [[ ${server} == "true" ]]; then
    bootstrap_expect="\"bootstrap_expect\": ${cluster_size},"
    filename="server"
    server="true"
    ui="true"
  fi

  cat << EOF > "$consul_config_dir/$filename.json"
{
  "advertise_addr": "$instance_ip_address",
  "bind_addr": "$instance_ip_address",
  $bootstrap_expect
  "datacenter": "$datacenter",
  "retry_join": [
    "provider=aws region=$region tag_key=$CONSUL_TAG_KEY tag_value=$CONSUL_TAG_VALUE"
  ],
  "server": $server,
  "ui" : $ui
}
EOF
}

function configure_hostname {
  local readonly hostname_file="/etc/names.txt"
  local readonly hostname="$(sort -R $hostname_file| head -n 1)-$(sort -R $hostname_file | head -n 1)"
  local readonly new_hostname=$(echo $hostname | cut -c 1-15)

  hostnamectl set-hostname $new_hostname
}

function configure_dns_resolution {
  cat << EOF > /etc/systemd/resolved.conf
[Resolve]
DNS=$EC2_LOCAL_IPV4
FallbackDNS=8.8.8.8 8.8.4.4 2001:4860:4860::8888 2001:4860:4860::8844
EOF

  # Remove /etc/resolv.conf as it is a symlink to a dynamically generated file
  # created by systemd-resolved. Without this, when systemd-resolved is
  # reloaded, there will be two nameservers on /etc/resolv.conf: our local ipv4
  # and the AWS DNS ip for the subnet. This will cause DNS queries to be
  # load-balanced between the two nameservers, but only our local ipv4 can
  # resolve .consul queries.
  rm -f /etc/resolv.conf

  cat << EOF > /etc/resolv.conf
nameserver $EC2_LOCAL_IPV4
EOF

  systemctl daemon-reload
  systemctl restart dnsmasq
}

# ------------------------------------------------------------------------------
# RUN
# ------------------------------------------------------------------------------

function start_consul {
  systemctl start consul
}

function run {
  local readonly metadata_nosce_file="/etc/nosce/metadata"
  local readonly consul_nosce_file="/etc/nosce/consul"
  local readonly consul_config_dir="/etc/consul.d"

  log_info "Building EC2 Metadata"
  build_ec2_metadata $metadata_nosce_file

  log_info "Building Consul Metadata"
  build_consul_metadata $consul_nosce_file

  log_info "Building Consul Configuration"
  build_consul_configuration $consul_config_dir

  log_info "Configuring DNS Resolution"
  configure_dns_resolution

  log_info "Configuring hostname"
  configure_hostname

  log_info "Starting Consul"
  start_consul
}

run "$@"
