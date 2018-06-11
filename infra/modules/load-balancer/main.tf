# -----------------------------------------------------------------------------
# LOAD BALANCER
# -----------------------------------------------------------------------------

resource "aws_elb" "load_balancer" {
  internal        = "${var.internal}"
  name            = "${var.name}-lb"
  security_groups = ["${var.security_group_ids}"]
  subnets         = ["${var.subnet_ids}"]

  listener     = ["${var.listeners}"]
  health_check = ["${var.health_checks}"]

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags {
    Name = "${var.name} load balancer"
  }

  lifecycle {
    create_before_destroy = true
  }
}

# -----------------------------------------------------------------------------
# AUTOSCALING GROUP ATTACHMENT
# -----------------------------------------------------------------------------

resource "aws_autoscaling_attachment" "asg_attachment" {
  autoscaling_group_name = "${var.autoscaling_group_id}"
  elb                    = "${aws_elb.load_balancer.id}"
}

# -----------------------------------------------------------------------------
# DNS RECORDS
# -----------------------------------------------------------------------------

data "aws_route53_zone" "dns_base" {
  name         = "${var.dns_domain}."
  private_zone = false
}

resource "aws_route53_record" "record" {
  zone_id = "${data.aws_route53_zone.dns_base.zone_id}"
  name    = "${var.dns_name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${aws_elb.load_balancer.dns_name}"]
}
