job "podcasts" {
  datacenters = ["dc1"]
  type = "service"
  group "podcasts" {
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
      name = "podcasts"
      port = "80"
      address_mode = "alloc"
      tags = [
        "traefik.enable=true",
      ]
      connect {
        sidecar_service {}
      }
    }
    task "podcasts" {
      driver = "docker"
      env {
        TZ = "Europe/Athens"
      }
      config {
        image = "advplyr/audiobookshelf:2.19.4"
        security_opt = [
          "seccomp=unconfined"
        ]
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d+\\.\\d+\\.\\d+$"
        }
        volumes = [
          "/home/lgian/podcasts/podcasts:/podcasts",
          "/home/lgian/podcasts/config:/config",
          "/home/lgian/podcasts/metadata:/metadata",
        ]
      }
    }
  }
}
