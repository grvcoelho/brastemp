output "vpc_id" {
  value = "${aws_vpc.vpc.id}"
}

output "public_subnets_ids" {
  value = ["${aws_subnet.public.*.id}"]
}

output "private_subnets_ids" {
  value = ["${aws_subnet.private.*.id}"]
}

output "public_route_tables_ids" {
  value = ["${aws_route_table.public.*.id}"]
}

output "private_route_tables_ids" {
  value = ["${aws_route_table.private.*.id}"]
}
