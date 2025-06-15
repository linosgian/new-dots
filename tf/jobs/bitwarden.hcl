job "bitwarden" {
  datacenters = ["dc1"]
  type = "service"
  group "bitwarden" {
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
      name = "pass"
      port = "80"
      address_mode = "alloc"
      tags = [
        "traefik.enable=true",
      ]
      connect {
        sidecar_service {}
      }
    }
    task "bitwarden" {
      driver = "docker"
      env {
        TZ = "Europe/Athens"
        WEBSOCKET_ENABLED = true
        SIGNUPS_ALLOWED = false
      }
      user = "1000:1000"
      config {
        image = "vaultwarden/server:1.34.1"
        security_opt = [
          "seccomp=unconfined"
        ]
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d+\\.\\d+\\.\\d+$"
        }
        volumes = [
          "/zfs/bitwarden:/data"
        ]
      }
      resources {
        memory = 256
      }
    }
  }
}
