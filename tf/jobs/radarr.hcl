job "radarr" {
  datacenters = ["dc1"]
  type = "service"
  group "radarr" {
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
      name = "movies"
      port = "7878"
      address_mode = "alloc"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.movies.middlewares=traefiksso@file"
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
    task "radarr-docker" {
      driver = "docker"
      env {
        TZ = "Europe/Athens"
        PUID = 1000
        PGID = 1000
      }
      config {
        image = "linuxserver/radarr:5.26.2"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d+\\.\\d+\\.\\d+$"
        }
        volumes = [
          "/zfs/radarr/config:/config/",
          "/zfs/torrents/complete/movies/:/movies",
          "/zfs/qbit/downloads:/downloads",
        ]
      }
      resources {
        memory = 512
      }
    }
  }
}
