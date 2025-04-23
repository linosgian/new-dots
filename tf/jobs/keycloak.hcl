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
      name = "id-int"
      port = "8443"
      address_mode = "alloc"
      tags = [
        "traefik.enable=false",
      ]
      connect {
        sidecar_service {}
      }
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
        POSTGRES_PASSWORD="${keycloak_password}"
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
          "/zfs/keycloak/database/data:/var/lib/postgresql/data"
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
        DB_PASSWORD="${keycloak_db_password}"
        KEYCLOAK_ADMIN_USER="admin"
        KEYCLOAK_ADMIN_PASSWORD="${keycloak_password}"
        KEYCLOAK_PRODUCTION="true"
        KEYCLOAK_HOSTNAME="id.lgian.com"
        KEYCLOAK_PROXY_HEADERS="xforwarded"
        KEYCLOAK_HTTPS_KEY_STORE_FILE="/keystore.jks"
        KEYCLOAK_HTTPS_KEY_STORE_PASSWORD="whocares"
        KEYCLOAK_HTTPS_TRUST_STORE_FILE="/truststore.jks"
        KEYCLOAK_HTTPS_TRUST_STORE_PASSWORD="whocares"
        KEYCLOAK_HTTPS_PORT = "8443"
        KEYCLOAK_ENABLE_HTTPS = "true"

        # This is required to run keycloak behind traefik
        PROXY_ADDRESS_FORWARDING="true"

        TZ="Europe/Athens"
      }
      config {
        image = "bitnami/keycloak:26.2.0"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d+\\.\\d+\\.\\d+$"
        }
        security_opt = [
          "seccomp=unconfined"
        ]
        volumes = [
          "/var/lib/keycloak/certs/truststore.jks:/truststore.jks",
          "/var/lib/keycloak/certs/keystore.jks:/keystore.jks"
        ]
      }
      resources {
        memory = 1024
      }
    }
  }
}
