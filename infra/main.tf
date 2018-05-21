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
# AMIS
# -----------------------------------------------------------------------------

data "aws_ami" "brastemp" {
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "name"
    values = ["brastemp/arch-linux-lts-standard-*"]
  }
}

# -----------------------------------------------------------------------------
# BASTION
# -----------------------------------------------------------------------------

module "bastion" {
  source = "./modules/bastion"

  name = "${var.name}-bastion"

  cluster_size  = 1
  instance_type = "t2.micro"

  ami_id       = "${data.aws_ami.brastemp.image_id}"
  user_data    = "${data.template_file.init_bastion.rendered}"
  ssh_key_name = "${var.ssh_key_name}"

  vpc_id     = "${module.network.vpc_id}"
  subnet_ids = "${module.network.public_subnets_ids}"

  allowed_ssh_cidr_blocks = ["0.0.0.0/0"]
}

data "template_file" "init_bastion" {
  template = "${file("${path.module}/modules/userdata/init-bastion.sh")}"
}

# -----------------------------------------------------------------------------
# CONSUL SERVERS
# -----------------------------------------------------------------------------

module "brastemp_servers" {
  source = "./modules/brastemp-cluster"

  name = "${var.name}-server"

  cluster_size  = "${var.cluster_size}"
  instance_type = "t2.micro"

  cluster_tag_key   = "${var.cluster_tag_key}"
  cluster_tag_value = "${var.cluster_tag_value}"

  ami_id       = "${data.aws_ami.brastemp.image_id}"
  user_data    = "${data.template_file.init_brastemp_server.rendered}"
  ssh_key_name = "${var.ssh_key_name}"

  vpc_id     = "${module.network.vpc_id}"
  subnet_ids = "${module.network.private_subnets_ids}"

  allowed_inbound_cidr_blocks    = ["0.0.0.0/0"]
  allowed_ssh_security_group_ids = ["${module.bastion.security_group_id}"]
}

data "template_file" "init_brastemp_server" {
  template = "${file("${path.module}/modules/userdata/init-brastemp-agent.sh")}"

  vars {
    cluster_size      = "${var.cluster_size}"
    cluster_tag_key   = "${var.cluster_tag_key}"
    cluster_tag_value = "${var.cluster_tag_value}"

    datacenter = "dc1"
    region     = "${var.aws_region}"
    server     = "true"
  }
}

# -----------------------------------------------------------------------------
# CONSUL CLIENTS
# -----------------------------------------------------------------------------

module "brastemp_clients" {
  source = "./modules/brastemp-cluster"

  name = "${var.name}-client"

  cluster_size  = "${var.cluster_size}"
  instance_type = "t2.micro"

  cluster_tag_key   = "${var.cluster_tag_key}"
  cluster_tag_value = "${var.cluster_tag_value}"

  ami_id       = "${data.aws_ami.brastemp.image_id}"
  user_data    = "${data.template_file.init_brastemp_client.rendered}"
  ssh_key_name = "${var.ssh_key_name}"

  vpc_id     = "${module.network.vpc_id}"
  subnet_ids = "${module.network.private_subnets_ids}"

  allowed_inbound_cidr_blocks    = ["0.0.0.0/0"]
  allowed_ssh_security_group_ids = ["${module.bastion.security_group_id}"]
}

data "template_file" "init_brastemp_client" {
  template = "${file("${path.module}/modules/userdata/init-brastemp-agent.sh")}"

  vars {
    cluster_size      = "${var.cluster_size}"
    cluster_tag_key   = "${var.cluster_tag_key}"
    cluster_tag_value = "${var.cluster_tag_value}"

    datacenter = "dc1"
    region     = "${var.aws_region}"
    server     = "false"
  }
}
