# -----------------------------------------------------------------------------
# SECURITY GROUPS
# -----------------------------------------------------------------------------

resource "aws_security_group" "bastion_security_group" {
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

  security_group_id = "${aws_security_group.bastion_security_group.id}"
}

resource "aws_security_group_rule" "allow_ssh_inbound_from_security_group_ids" {
  count                    = "${length(var.allowed_ssh_security_group_ids)}"
  type                     = "ingress"
  from_port                = "22"
  to_port                  = "22"
  protocol                 = "tcp"
  source_security_group_id = "${element(var.allowed_ssh_security_group_ids, count.index)}"

  security_group_id = "${aws_security_group.bastion_security_group.id}"
}

resource "aws_security_group_rule" "allow_all_outbound" {
  type        = "egress"
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = "${aws_security_group.bastion_security_group.id}"
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

# -----------------------------------------------------------------------------
# LAUNCH_CONFIGURATION AND AUTO_SCALING_GROUPS
# -----------------------------------------------------------------------------

resource "aws_instance" "bastion" {
  count         = "${var.cluster_size}"
  ami           = "${var.ami_id}"
  instance_type = "${var.instance_type}"
  user_data     = "${var.user_data}"

  iam_instance_profile = "${aws_iam_instance_profile.instance_profile.name}"
  key_name             = "${var.ssh_key_name}"
  security_groups      = ["${aws_security_group.bastion_security_group.id}"]
  subnet_id            = "${element(var.subnet_ids, 0)}"

  root_block_device {
    volume_type           = "${var.root_volume_type}"
    volume_size           = "${var.root_volume_size}"
    delete_on_termination = "${var.root_volume_delete_on_termination}"
  }

  tags {
    Name = "${var.name}"
  }
}
