# -----------------------------------------------------------------------------
# PROVIDERS
# -----------------------------------------------------------------------------

provider "nomad" {
  address = "${var.nomad_address}"
  region  = "${var.nomad_region}"
}

provider "aws" {
  region  = "${var.aws_region}"
  profile = "${var.aws_profile}"
}

# -----------------------------------------------------------------------------
# DNS
# -----------------------------------------------------------------------------

data "aws_route53_zone" "dns_base" {
  name         = "${var.dns_domain}."
  private_zone = false
}

# -----------------------------------------------------------------------------
# TRAEFIK
# Launch traefik, a reverse proxy that will connect to consul and expose our
# services to the web
# -----------------------------------------------------------------------------

data "template_file" "traefik_job_file" {
  template = "${file("${path.module}/jobs/traefik.nomad")}"

  vars {
    job_name       = "traefik"
    image          = "pagarme/traefik-docker-consul"
    datacenter     = "${var.datacenter}"
    traefik_domain = "${var.dns_domain}"
    traefik_tag    = "${var.traefik_tag}"
  }
}

resource "nomad_job" "traefik_job" {
  jobspec = "${data.template_file.traefik_job_file.rendered}"
}

resource "aws_route53_record" "traefik_record" {
  zone_id = "${data.aws_route53_zone.dns_base.zone_id}"
  name    = "traefik.${data.aws_route53_zone.dns_base.name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${var.load_balancer_dns_name}"]
}

# -----------------------------------------------------------------------------
# HELLO
# A simple service that says hi and outputs the hostname
# -----------------------------------------------------------------------------

data "template_file" "hello_job_file" {
  template = "${file("${path.module}/jobs/hello.nomad")}"

  vars {
    job_name       = "hello"
    image          = "tutum/hello-world"
    datacenter     = "${var.datacenter}"
    traefik_domain = "${var.dns_domain}"
    traefik_tag    = "${var.traefik_tag}"
  }
}

resource "nomad_job" "hello_job" {
  jobspec = "${data.template_file.hello_job_file.rendered}"
}

# -----------------------------------------------------------------------------
# WHOAMI
# A service that outputs request parameters
# -----------------------------------------------------------------------------

data "template_file" "whoami_job_file" {
  template = "${file("${path.module}/jobs/whoami.nomad")}"

  vars {
    job_name       = "whoami"
    image          = "emilevauge/whoami"
    datacenter     = "${var.datacenter}"
    traefik_domain = "${var.dns_domain}"
    traefik_tag    = "${var.traefik_tag}"
  }
}

resource "nomad_job" "whoami_job" {
  jobspec = "${data.template_file.whoami_job_file.rendered}"
}

resource "aws_route53_record" "whoami_record" {
  zone_id = "${data.aws_route53_zone.dns_base.zone_id}"
  name    = "whoami.${data.aws_route53_zone.dns_base.name}"
  type    = "CNAME"
  ttl     = "300"
  records = ["${var.load_balancer_dns_name}"]
}
