# -----------------------------------------------------------------------------
# PROVIDER
# -----------------------------------------------------------------------------
provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

# -----------------------------------------------------------------------------
# NETWORK
# -----------------------------------------------------------------------------

module "network" {
  source = "./modules/network"
  name   = "${var.name}"

  vpc_cidr_block = "17.10.0.0/16"

  availability_zones = [
    "${var.aws_region}a",
    "${var.aws_region}b",
  ]
}

# -----------------------------------------------------------------------------
# CONSUL SERVERS
# -----------------------------------------------------------------------------

data "aws_ami" "consul" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["hashistack-arch-linux-lts-standard-*"]
  }
}

module "consul_servers" {
  source = "./modules/consul-cluster"

  cluster_name  = "${var.name}-server"
  cluster_size  = "${var.cluster_size}"
  instance_type = "t2.micro"

  cluster_tag_key   = "${var.cluster_tag_key}"
  cluster_tag_value = "${var.cluster_tag_value}"

  ami_id       = "${data.aws_ami.consul.image_id}"
  user_data    = "${data.template_file.user_data_server.rendered}"
  ssh_key_name = "${var.ssh_key_name}"

  vpc_id     = "${module.network.vpc_id}"
  subnet_ids = "${module.network.private_subnets_ids}"

  allowed_ssh_cidr_blocks     = ["0.0.0.0/0"]
  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
}

data "template_file" "user_data_server" {
  template = "${file("${path.module}/modules/scripts/user-data-server.sh")}"

  vars {
    cluster_tag_key   = "${var.cluster_tag_key}"
    cluster_tag_value = "${var.cluster_tag_value}"
  }
}
