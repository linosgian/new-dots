job "jackett" {
  datacenters = ["dc1"]
  type = "service"
  group "jackett" {
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
      name = "jackett"
      port = "9117"
      address_mode = "alloc"
      tags = [
        "traefik.enable=true",
      ]
      connect {
        sidecar_service {}
      }
    }
    task "jackett-docker" {
      driver = "docker"
      env {
        TZ = "Europe/Athens"
        PUID = 1000
        PGID = 1000
      }
      config {
        image = "linuxserver/jackett:0.22.1116"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d+\\.\\d+\\.\\d+$"
        }
        # volumes = [
        #   "/zfs/jackett:/config/",
        # ]
      }
    }
  }
}
