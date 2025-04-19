job "updates" {
  datacenters = ["dc1"]
  type = "service"
  group "updates" {
    count = 1
    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }
    network {
      mode = "bridge"
    }

    service {
      name = "updates"
      port = "3000"
      address_mode = "alloc"
      tags = [
        "traefik.enable=true",
      ]
      connect {
        sidecar_service {}
      }
    }
    task "updates" {
      driver = "docker"
      env {
        TZ="Europe/Athens"
        WUD_WATCHER_LOCAL_WATCHBYDEFAULT = "false"
      }
      config {
        image = "ghcr.io/fmartinou/whats-up-docker:6.6.1"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d+\\.\\d+\\.\\d+$"
        }
        volumes = [
          "/var/run/docker.sock:/var/run/docker.sock"
        ]
      }
      resources {
        memory = 512
      }
    }
  }
}
