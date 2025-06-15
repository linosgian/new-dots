job "bazarr" {
  datacenters = ["dc1"]
  type = "service"
  group "bazarr" {
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
      name = "subs"
      port = "6767"
      address_mode = "alloc"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.subs.middlewares=traefiksso@file"
      ]
      connect {
        sidecar_service {
          disable_default_tcp_check = true
          proxy {
            config {
              envoy_prometheus_bind_addr = "0.0.0.0:9999"
            }

            upstreams {
              destination_name = "movies"
              local_bind_port = 8081
            }

            upstreams {
              destination_name = "series"
              local_bind_port = 8082
            }
          }
        }
      }
    }
    task "bazarr-docker" {
      driver = "docker"
      env {
        TZ = "Europe/Athens"
        PUID = 1000
        PGID = 1000
      }
      config {
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d+\\.\\d+\\.\\d+$"
        }
        image = "linuxserver/bazarr:1.5.2"
        volumes = [
          "/zfs/bazarr/config:/config/",
          "/zfs/torrents/complete/movies/:/movies",
          "/zfs/torrents/complete/series/:/series",
        ]
      }
      resources {
        memory = 512
      }
    }
  }
}
