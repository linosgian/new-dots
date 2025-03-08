locals {
  label_name = "diun.watch_repo"
}
job "qbit" {
    datacenters = ["dc1"]
    type = "service"
    group "qbit" {
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
      name = "torrents"
      port = "8080"
      address_mode = "alloc"
      tags = [
        "traefik.enable=true",
      ]
      connect {
        sidecar_service {}
      }
    }
    task "qbit-docker" {
      driver = "docker"
      env {
        PUID = 1000
        PGID = 1000
        TZ = "Europe/Athens"
      }
      config {
        image = "linuxserver/qbittorrent:5.0.3"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d{1}\\.\\d+\\.\\d+$"
        }
        # volumes = [
        #   "/zfs/qbit/config:/config/",
        #   "/zfs/qbit/vuetorrent/:/vue",
        #   "/zfs/qbit/downloads/:/downloads/",
        # ]
      }
    }
  }
}
