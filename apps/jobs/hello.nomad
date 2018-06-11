job "${job_name}" {
  type = "service"
  datacenters = ["${datacenter}"]

	update {
		stagger = "5s"
		max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "20s"
    auto_revert = true
	}

  group "web" {
    count = 3

    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    ephemeral_disk {
      size = 300
    }

    task "web" {
      driver = "docker"

      config {
        image = "${image}"
        port_map {
          http = 80
        }
      }

      resources {
        cpu    = 100
        memory = 50

        network {
          mbits = 1

          port "http" {}
        }
      }

      service {
        name = "hello"
        port = "http"

        tags = [
          "traefik.enable=true",
          "traefik.tags=api",
          "traefik.tags=external",
        ]

        check {
          name     = "alive"
          type     = "tcp"
          interval = "10s"
          timeout  = "2s"
        }
      }

      env {
        TRAEFIK_CONSUL_HOST  = "consul.service.consul"
        TRAEFIK_CONSUL_PORT  = "8500"
        TRAEFIK_DOMAIN       = "${traefik_domain}"
        TRAEFIK_TAG          = "${traefik_tag}"
      }
    }
  }
}
