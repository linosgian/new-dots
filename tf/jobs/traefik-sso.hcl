job "traefiksso" {
  datacenters = ["dc1"]
  type        = "service"
  group "traefiksso" {
    count = 1
    restart {
      attempts = 10
      interval = "5m"
      delay = "15s"
      mode = "delay"
    }
    network {
      mode = "bridge"
    }
    service {
      name = "traefiksso"
      port = "4181"
      address_mode = "alloc"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.traefiksso.rule=Path(`/_oauth`)"
      ]
      connect {
        sidecar_service {}
      }
    }
    task "traefiksso" {
      driver = "docker"
      env {
        TZ="Europe/Athens"
        CLIENT_ID= "traefik"
        CLIENT_SECRET= "MUW13Fopa6XnvAOf2JMKvnEZ58lQM7eq"
        ENCRYPTION_KEY= "RZcmLKDJDRx52no5dXGm8mYGtBL5jjCa"
        PROVIDER_URI= "http://id.service.consul/realms/master"
        SECRET= "kNyUWQk8t6Hvfi8izhKgxVBt962VZnfJ"
        AUTH_HOST= "keycloak"
        COOKIE_DOMAIN= "localhost"
      }

      config {
        image = "mesosphere/traefik-forward-auth:3.1.0"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d+\\.\\d+\\.\\d+$"
        }
      }
    }
  }
}
