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

  vpc_cidr_block = "10.10.0.0/16"

  availability_zones = [
    "${var.aws_region}a",
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
# BRASTEMP SERVERS
# -----------------------------------------------------------------------------

module "brastemp_servers" {
  source = "./modules/brastemp-cluster"

  name   = "${var.name}-server"
  server = true

  cluster_size  = "${var.cluster_size}"
  instance_type = "t2.micro"

  cluster_tag_key   = "${var.cluster_tag_key}"
  cluster_tag_value = "${var.cluster_tag_value}"

  ami_id       = "${data.aws_ami.brastemp.image_id}"
  user_data    = "${data.template_file.init_brastemp_server.rendered}"
  ssh_key_name = "${var.ssh_key_name}"

  vpc_id     = "${module.network.vpc_id}"
  subnet_ids = "${module.network.public_subnet_ids}"

  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
  allowed_ssh_cidr_blocks     = ["0.0.0.0/0"]
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
# BRASTEMP CLIENTS
# -----------------------------------------------------------------------------

module "brastemp_clients" {
  source = "./modules/brastemp-cluster"

  name   = "${var.name}-client"
  server = false

  cluster_size  = "${var.cluster_size}"
  instance_type = "t2.micro"

  cluster_tag_key   = "${var.cluster_tag_key}"
  cluster_tag_value = "${var.cluster_tag_value}"

  ami_id       = "${data.aws_ami.brastemp.image_id}"
  user_data    = "${data.template_file.init_brastemp_client.rendered}"
  ssh_key_name = "${var.ssh_key_name}"

  vpc_id     = "${module.network.vpc_id}"
  subnet_ids = "${module.network.public_subnet_ids}"

  allowed_inbound_cidr_blocks = ["0.0.0.0/0"]
  allowed_ssh_cidr_blocks     = ["0.0.0.0/0"]
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

# -----------------------------------------------------------------------------
# LOAD BALANCING
# -----------------------------------------------------------------------------

module "brastemp_client_lb" {
  source = "./modules/load-balancer"

  name                 = "${var.name}-client"
  internal             = false
  security_group_ids   = ["${module.brastemp_clients.security_group_id}"]
  subnet_ids           = ["${module.brastemp_clients.subnet_ids}"]
  autoscaling_group_id = "${module.brastemp_clients.asg_id}"

  dns_domain = "${var.dns_domain}"
  dns_name   = "lb.${var.dns_domain}"

  listeners = [
    {
      instance_port     = "80"
      instance_protocol = "HTTP"
      lb_port           = "80"
      lb_protocol       = "HTTP"
    },
    {
      instance_port     = "8080"
      instance_protocol = "HTTP"
      lb_port           = "8080"
      lb_protocol       = "HTTP"
    },
  ]

  health_checks = [
    {
      target              = "TCP:8080"
      interval            = 30
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
    },
  ]
}
