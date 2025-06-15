job "snmp-exporter" {
  datacenters = ["dc1"]
  type = "service"
  group "snmp-exporter" {
    network {
      mode = "bridge"
      port "http" {
        to = "9116"
        host_network = "private"
      }
    }
    count = 1
    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }
    task "snmp-exporter" {
      driver = "docker"
      config {
        network_mode = "bridge"
        image = "prom/snmp-exporter:v0.29.0"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^v\\d+\\.\\d+\\.\\d+$"
        }
      }
      resources {
        memory = 256
      }
      service {
        name = "snmp-exporter"
        port = "http"
        address_mode = "driver"
        tags = [
          "prometheus-exporter",
        ]
      }
    }
  }
}
