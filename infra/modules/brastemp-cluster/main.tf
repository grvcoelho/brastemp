# -----------------------------------------------------------------------------
# SECURITY GROUPS
# -----------------------------------------------------------------------------

resource "aws_security_group" "lc_security_group" {
  name_prefix = "${var.name}"
  description = "Security group for the ${var.name} launch configuration"
  vpc_id      = "${var.vpc_id}"

  tags {
    Name = "${var.name}"
  }
}

resource "aws_security_group_rule" "allow_ssh_inbound" {
  count       = "${length(var.allowed_ssh_cidr_blocks) >= 1 ? 1 : 0}"
  type        = "ingress"
  from_port   = "22"
  to_port     = "22"
  protocol    = "tcp"
  cidr_blocks = ["${var.allowed_ssh_cidr_blocks}"]

  security_group_id = "${aws_security_group.lc_security_group.id}"
}

resource "aws_security_group_rule" "allow_ssh_inbound_from_security_group_ids" {
  count                    = "${length(var.allowed_ssh_security_group_ids)}"
  type                     = "ingress"
  from_port                = "22"
  to_port                  = "22"
  protocol                 = "tcp"
  source_security_group_id = "${element(var.allowed_ssh_security_group_ids, count.index)}"

  security_group_id = "${aws_security_group.lc_security_group.id}"
}

resource "aws_security_group_rule" "allow_lb_http_inbound" {
  count       = "${var.server ? 0 : 1}"
  type        = "ingress"
  from_port   = "80"
  to_port     = "80"
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.lc_security_group.id}"
}

resource "aws_security_group_rule" "allow_lb_admin_inbound" {
  count       = "${var.server ? 0 : 1}"
  type        = "ingress"
  from_port   = "8080"
  to_port     = "8080"
  protocol    = "tcp"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.lc_security_group.id}"
}

resource "aws_security_group_rule" "allow_self_all" {
  type      = "ingress"
  from_port = 0
  to_port   = 0
  protocol  = -1
  self      = true

  security_group_id = "${aws_security_group.lc_security_group.id}"
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.lc_security_group.id}"
}

module "consul_security_group_rules" {
  source = "../consul-security-group-rules"

  security_group_id                  = "${aws_security_group.lc_security_group.id}"
  allowed_inbound_cidr_blocks        = ["${var.allowed_inbound_cidr_blocks}"]
  allowed_inbound_security_group_ids = ["${var.allowed_inbound_security_group_ids}"]
}

module "nomad_security_group_rules" {
  source = "../nomad-security-group-rules"

  security_group_id                  = "${aws_security_group.lc_security_group.id}"
  allowed_inbound_cidr_blocks        = ["${var.allowed_inbound_cidr_blocks}"]
  allowed_inbound_security_group_ids = ["${var.allowed_inbound_security_group_ids}"]
}

# -----------------------------------------------------------------------------
# IAM, PERMISSIONS AND ROLES
# -----------------------------------------------------------------------------

resource "aws_iam_instance_profile" "instance_profile" {
  name_prefix = "${var.name}"
  role        = "${aws_iam_role.instance_role.name}"
}

resource "aws_iam_role" "instance_role" {
  name_prefix        = "${var.name}"
  assume_role_policy = "${data.aws_iam_policy_document.instance_role.json}"
}

data "aws_iam_policy_document" "instance_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

module "iam_policies" {
  source = "../consul-iam-policies"

  iam_role_id = "${aws_iam_role.instance_role.id}"
}

# -----------------------------------------------------------------------------
# LAUNCH_CONFIGURATION AND AUTO_SCALING_GROUPS
# -----------------------------------------------------------------------------

resource "aws_launch_configuration" "launch_configuration" {
  name_prefix   = "${var.name}"
  image_id      = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  user_data     = "${var.user_data}"

  iam_instance_profile = "${aws_iam_instance_profile.instance_profile.name}"
  key_name             = "${var.ssh_key_name}"
  security_groups      = ["${aws_security_group.lc_security_group.id}"]

  root_block_device {
    volume_type           = "${var.root_volume_type}"
    volume_size           = "${var.root_volume_size}"
    delete_on_termination = "${var.root_volume_delete_on_termination}"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name = "${var.name}-${aws_launch_configuration.launch_configuration.name}"

  launch_configuration = "${aws_launch_configuration.launch_configuration.name}"

  availability_zones  = ["${var.availability_zones}"]
  vpc_zone_identifier = ["${var.subnet_ids}"]

  min_size         = "${var.cluster_size}"
  max_size         = "${var.cluster_size}"
  desired_capacity = "${var.cluster_size}"

  health_check_type         = "EC2"
  health_check_grace_period = 300
  wait_for_capacity_timeout = "10m"

  lifecycle {
    create_before_destroy = true
  }

  tags = [
    {
      key                 = "Name"
      value               = "${var.name}"
      propagate_at_launch = true
    },
    {
      key                 = "${var.cluster_tag_key}"
      value               = "${var.cluster_tag_value}"
      propagate_at_launch = true
    },
    "${var.tags}",
  ]
}
