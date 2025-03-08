job "blackbox-exporter" {
  datacenters = ["dc1"]
  type = "service"

  group "monitoring" {
    count = 1
    network {
      port "http" {
        to = "9115"
      }
      mode = "bridge"
    }
    service {
      name = "blackbox"
      port = "http"
      address_mode = "alloc"
      check {
        type = "http"
        path = "/-/healthy"
        interval = "10s"
        timeout = "2s"
      }
    }
    restart {
      attempts = 3
      delay    = "20s"
      mode     = "delay"
    }

    task "blackbox-exporter" {
      driver = "docker"
      config {
        image = "prom/blackbox-exporter:v0.23.0"
      }
    }
  }
}

