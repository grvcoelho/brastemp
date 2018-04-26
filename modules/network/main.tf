locals {
  az_count = "${length(var.availability_zones)}"
}

resource "aws_vpc" "vpc" {
  cidr_block           = "${var.vpc_cidr_block}"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name = "${var.name} network"
  }
}

resource "aws_eip" "nat" {
  count = "${local.az_count}"
  vpc   = true
}

resource "aws_internet_gateway" "ig" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_nat_gateway" "nat" {
  count         = "${local.az_count}"
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.public.*.id, count.index)}"
  depends_on    = ["aws_internet_gateway.ig"]
}

resource "aws_subnet" "private" {
  count      = "${local.az_count}"
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "${cidrsubnet(var.vpc_cidr_block, 8, count.index)}"

  availability_zone       = "${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.name} private ${element(var.availability_zones, count.index)}"
  }
}

resource "aws_subnet" "public" {
  count      = "${local.az_count}"
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "${cidrsubnet(var.vpc_cidr_block, 8, count.index + 128)}"

  availability_zone       = "${element(var.availability_zones, count.index)}"
  map_public_ip_on_launch = true

  tags {
    Name = "${var.name} public ${element(var.availability_zones, count.index)}"
  }
}

resource "aws_route_table" "public" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "${var.name} public"
  }
}

resource "aws_route" "public" {
  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = "${aws_route_table.public.id}"
  gateway_id             = "${aws_internet_gateway.ig.id}"
}

resource "aws_route_table_association" "public" {
  count          = "${local.az_count}"
  subnet_id      = "${element(aws_subnet.public.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table" "private" {
  count  = "${local.az_count}"
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name = "${var.name} private"
  }
}

resource "aws_route" "private" {
  count = "${local.az_count}"

  destination_cidr_block = "0.0.0.0/0"
  route_table_id         = "${element(aws_route_table.private.*.id, count.index)}"
  nat_gateway_id         = "${element(aws_nat_gateway.nat.*.id, count.index)}"
}

resource "aws_route_table_association" "private" {
  count          = "${local.az_count}"
  subnet_id      = "${element(aws_subnet.private.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.private.*.id, count.index)}"
}
