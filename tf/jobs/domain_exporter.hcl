job "domain-exporter" {
  datacenters = ["dc1"]
  type = "service"

  group "domainexporter" {
    count = 1
    network {
      mode = "bridge"
      port "exposed" {
        host_network = "private"
      }
    }
    service {
      name = "domain-exporter"
      tags = [ "metrics" ]
      connect {
        sidecar_service{}
      }
      port = "9222"
      check {
        type = "http"
        port = "exposed"
        path = "/"
        interval = "10s"
        expose = true
        timeout = "2s"
      }
    }
    restart {
      attempts = 10
      delay    = "20s"
      mode     = "delay"
    }

    task "domain-exporter" {
      driver = "docker"
      config {
        image = "caarlos0/domain_exporter:v1.24.1"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^v\\d+\\.\\d+\\.\\d+$"
        }
        args = [
          "--bind=127.0.0.1:9222",
        ]
      }
      resources {
        memory = 150
      }
    }
  }
}

