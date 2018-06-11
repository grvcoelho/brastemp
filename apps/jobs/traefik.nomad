job "${job_name}" {
  type = "system"
  datacenters = ["${datacenter}"]

	update {
		stagger = "5s"
		max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "20s"
    auto_revert = true
	}

  constraint {
    distinct_hosts = true
  }

  group "traefik" {
    restart {
      attempts = 10
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }

    task "traefik" {
      driver = "docker"

      config {
        image = "${image}"
        port_map {
          http = 80
          admin = 8080
        }
      }

      resources {
        cpu    = 100
        memory = 50

        network {
          mbits = 1

          port "http" {
            static = 80
          }

          port "admin" {
            static = 8080
          }
        }
      }

      service {
        name = "traefik"
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

      service {
        name = "traefik-admin"
        port = "admin"

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
