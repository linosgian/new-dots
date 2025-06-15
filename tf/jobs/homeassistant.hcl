job "assistant" {
  datacenters = ["dc1"]
  type = "service"
  group "assistant" {
    count = 1
    restart {
      attempts = 2
      interval = "30m"
      delay = "15s"
      mode = "fail"
    }
    network {
      mode = "bridge"
      port "connect_proxy_assistant" {
        to = 8123
        host_network = "private"
      }
    }

    service {
      name = "assistant"
      port = "8123"
      address_mode = "alloc"
      tags = [
        "traefik.enable=true",
      ]
      connect {
        sidecar_service {}
      }
    }
    task "assistant" {
      driver = "docker"
      env {
        TZ = "Europe/Athens"
      }
      config {
        image = "homeassistant/home-assistant:2025.6.1"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d+\\.\\d+\\.\\d+$"
        }
        volumes = [
          "/zfs/homeassistant/:/config"
        ]
        args = [
        ]
      }
      resources {
        memory = 1024
      }
    }
  }
}

