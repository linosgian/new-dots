job "ytdl" {
  datacenters = ["dc1"]
  type = "service"
  group "ytdl" {
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
      name = "yt"
      port = "6767"
      address_mode = "alloc"
      connect {
        sidecar_service {
        }
      }
    }
    task "ytdl" {
      driver = "docker"
      env {
        TZ = "Europe/Athens"
        PUID = 1000
        PGID = 1000
        DOCKER_MODS = "linuxserver/mods:universal-cron"
      }
      config {
        image = "ghcr.io/jmbannon/ytdl-sub:latest"
        labels = {
          "wud.watch" = "true"
          "wud.watch.digest" = "true"
          "wud.tag.include" = "^latest$"
        }
        volumes = [
          "/zfs/ytdl/config:/config/",
          "/zfs/ytdl/downloads/movies:/movies",
          "/zfs/ytdl/downloads/tv_shows:/tv_shows",
        ]
      }
      resources {
        memory = 256
      }
    }
  }
}
