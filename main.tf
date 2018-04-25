provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

resource "aws_instance" "app" {
  ami           = "ami-408c7f28"
  instance_type = "t1.micro"
}
