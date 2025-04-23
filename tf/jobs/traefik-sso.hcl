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
        sidecar_service {
          disable_default_tcp_check = true
          proxy {
            upstreams {
              destination_name = "id-int"
              local_bind_port = 443
            }
          }
        }
      }
    }
    task "traefiksso" {
      driver = "docker"
      env {
        TZ="Europe/Athens"
        CLIENT_ID= "traefik"
        CLIENT_SECRET= "${traefik_sso_client_secret}"
        ENCRYPTION_KEY= "${traefik_sso_encryption_key}"
        PROVIDER_URI= "https://id.lgian.com/realms/master"
        SECRET= "${traefik_sso_secret}"
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
