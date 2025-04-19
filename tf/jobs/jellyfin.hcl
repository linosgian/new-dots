job "jellyfin" {
  datacenters = ["dc1"]
  type = "service"
  group "jellyfin" {
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
      name = "jellyfin"
      port = "8096"
      address_mode = "alloc"
      tags = [
        "traefik.enable=true",
      ]
      connect {
        sidecar_service {
          disable_default_tcp_check = true
          proxy {
            upstreams {
              destination_name = "notifs"
              local_bind_port = 8080
            }
          }
        }
      }
    }
    task "jellyfin-docker" {
      driver = "docker"
      env {
        TZ = "Europe/Athens"
        ROC_ENABLE_PRE_VEGA="1"
      }
      user = "1000:1000"
      config {
        image = "jellyfin/jellyfin:10.10.7"
        group_add = [
          "107",
          "44"
        ]
        devices = [
          {
            host_path = "/dev/dri/renderD128"
            container_path = "/dev/dri/renderD128"
          },
        ]
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d+\\.\\d+\\.\\d+$"
        }
        volumes = [
          "/zfs/torrents/complete:/media/",
          "/zfs/jellyfin/config/:/config/",
          "/zfs/podcasts/:/podcasts/",
          "/ssd/cache/:/cache/",
          "/ssd/transcodes/:/config/transcodes",
          "/zfs/ytdl/downloads/tv_shows/:/ytdl",
          "/zfs/ytdl/downloads/movies/:/ytdl-singles",
        ]
      }
      resources {
        memory = 3048
        memory_max = 5096
      }
    }
  }
}
