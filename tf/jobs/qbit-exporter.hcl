job "qbit-exporter" {
    datacenters = ["dc1"]
    type = "service"
    group "qbit-exporter" {
      count = 1
      network {
        mode = "bridge"
      }
      restart {
        attempts = 2
        interval = "30m"
        delay = "15s"
        mode = "fail"
      }

    service {
      name = "torrents-exporter"
      port = "8090"
      address_mode = "alloc"
      connect {
        sidecar_service {
          disable_default_tcp_check = true
          proxy {
            upstreams {
              destination_name = "torrents"
              local_bind_port = 8080
            }
          }
        }
      }
    }
    task "qbit-exporter-docker" {
      driver = "docker"
      env {
        PUID = 1000
        PGID = 1000
        TZ = "Europe/Athens"
        QBITTORRENT_BASE_URL = "http://localhost:8080"
      }
      config {
        image = "ghcr.io/martabal/qbittorrent-exporter:v1.7.0"
      }
      resources {
        memory = 300
      }
    }
  }
}
