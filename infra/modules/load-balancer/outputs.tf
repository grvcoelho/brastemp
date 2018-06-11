output "elb_id" {
  value = "${aws_elb.load_balancer.id}"
}

output "dns_name" {
  value = "${var.dns_name}"
}
