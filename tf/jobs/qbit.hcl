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
      name = "tors"
      port = "3000"
      address_mode = "alloc"
      task = "flood"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.tors.middlewares=traefiksso@file"
      ]
      connect {
        sidecar_service {}
      }
    }
    service {
      name = "torrents"
      port = "8080"
      address_mode = "alloc"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.torrents.middlewares=traefiksso@file"
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
        image = "linuxserver/qbittorrent:5.1.2"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d{1}\\.\\d+\\.\\d+$"
        }
        volumes = [
          "/zfs/qbit/config:/config/",
          "/zfs/qbit/vuetorrent/:/vue",
          "/zfs/qbit/downloads/:/downloads/",
        ]
      }
      resources {
        memory = 1000
      }
    }
  }
}

