job "sonarr" {
  datacenters = ["dc1"]
  type = "service"
  group "sonarr" {
    count = 1
    restart {
      attempts = 20
      interval = "30m"
      delay = "5s"
      mode = "fail"
    }
    network {
      mode = "bridge"
    }

    service {
      name = "series"
      port = "8989"
      address_mode = "alloc"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.series.middlewares=traefiksso@file"
      ]
      connect {
        sidecar_service {
          disable_default_tcp_check = true
          proxy {
            upstreams {
              destination_name = "jackett"
              local_bind_port = 8082
            }
            upstreams {
              destination_name = "torrents"
              local_bind_port = 8081
            }
          }
        }
      }
    }
    task "sonarr-docker" {
      driver = "docker"
      env {
        TZ = "Europe/Athens"
        PUID = 1000
        PGID = 1000
      }
      config {
        security_opt = [
          "seccomp=unconfined"
        ]
        image = "linuxserver/sonarr:4.0.15"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d+\\.\\d+\\.\\d+$"
        }
        volumes = [
          "/zfs/sonarr/config:/config/",
          "/zfs/torrents/complete/series/:/series",
          "/zfs/qbit/downloads:/downloads",
        ]
      }
      resources {
        memory = 512
      }
    }
  }
}

