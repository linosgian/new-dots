job "keycloak" {
  datacenters = ["dc1"]
  type = "service"
  group "keycloak" {
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
      name = "id"
      port = "8080"
      address_mode = "alloc"
      tags = [
        "traefik.enable=true",
      ]
      connect {
        sidecar_service {}
      }
    }
    task "keycloak-db" {
      driver = "docker"
      env {
        POSTGRES_USER="keycloak"
        POSTGRES_PASSWORD="huGB9R4nZScVkH"
      }
      config {
        image = "postgres:15.3"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d+\\.\\d+\\.\\d+$"
        }
        security_opt = [
          "seccomp=unconfined"
        ]
        volumes = [
          "/home/lgian/foo/database/data:/var/lib/postgresql/data"
        ]
        volume_driver = "docker"
      }
    }
    task "keycloak" {
      driver = "docker"
      env {
        DB_DATABASE="keycloak"
        DB_ADDR="127.0.0.1"
        DB_USER="keycloak"
        DB_PASSWORD="huGB9R4nZScVkH"
        KEYCLOAK_ADMIN_USER="admin"
        KEYCLOAK_ADMIN_PASSWORD="e6BKxmtWKRg2rT"
        KEYCLOAK_PRODUCTION="true"
        KEYCLOAK_HOSTNAME="id.foo.lgian.com"
        KEYCLOAK_PROXY_HEADERS="xforwarded"

        # This is required to run keycloak behind traefik
        PROXY_ADDRESS_FORWARDING="true"

        TZ="Europe/Athens"
      }
      config {
        image = "bitnami/keycloak:26.0.7"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d+\\.\\d+\\.\\d+$"
        }
        security_opt = [
          "seccomp=unconfined"
        ]
      }
      resources {
        memory = 1024
      }
    }
  }
}
