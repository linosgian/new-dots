job "recipes" {
  datacenters = ["dc1"]
  type = "service"
  group "recipes" {
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
      name = "recipes"
      port = "9000"
      address_mode = "alloc"
      tags = [
        "traefik.enable=true",
      ]
      connect {
        sidecar_service {}
      }
    }
    task "recipes" {
      driver = "docker"
      env {
        RECIPE_PUBLIC="true"
        RECIPE_SHOW_NUTRITION="true"
        RECIPE_SHOW_ASSETS="true"
        RECIPE_LANDSCAPE_VIEW="true"
        RECIPE_DISABLE_COMMENTS="false"
        RECIPE_DISABLE_AMOUNT="false"
        PUID="1000"
        PGID="1000"
        TZ="Europe/Athens"
      }
      config {
        image = "hkotel/mealie:v2.8.0"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^v\\d+\\.\\d+\\.\\d+$"
        }
        volumes = [
          "/zfs/mealie-new:/app/data"
        ]
      }
      resources {
        memory = 512
      }
    }
  }
}
