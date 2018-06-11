# -----------------------------------------------------------------------------
# PROVIDER
# -----------------------------------------------------------------------------

provider "nomad" {
  address = "${var.nomad_address}"
  region  = "${var.nomad_region}"
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
    traefik_domain = "${var.traefik_domain}"
    traefik_tag    = "${var.traefik_tag}"
  }
}

resource "nomad_job" "traefik_job" {
  jobspec = "${data.template_file.traefik_job_file.rendered}"
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
    traefik_domain = "${var.traefik_domain}"
    traefik_tag    = "${var.traefik_tag}"
  }
}

resource "nomad_job" "hello_job" {
  jobspec = "${data.template_file.hello_job_file.rendered}"
}
