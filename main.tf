provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

module "network" {
  source = "./modules/network"
  name   = "${var.name}"

  vpc_cidr_block = "17.10.0.0/16"

  availability_zones = [
    "${var.aws_region}a",
    "${var.aws_region}b",
  ]
}
