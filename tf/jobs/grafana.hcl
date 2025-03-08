job "grafana" {
  datacenters = ["dc1"]
  type = "service"

  group "grafana" {
    restart {
      attempts = 10
      interval = "5m"
      delay = "10s"
      mode = "delay"
    }
    network {
      mode = "bridge"
      port "exposed" {}
    }
    service {
      name = "grafana"
      connect {
        sidecar_service{}
      }
      port = "3000"
      address_mode = "alloc"
      tags = [
        "traefik.enable=true",
      ]
      check {
        name     = "Grafana HTTP"
        type     = "http"
        port     = "exposed"
        path     = "/api/health"
        interval = "5s"
        timeout  = "2s"
        expose   = true
        check_restart {
          limit = 2
          grace = "60s"
          ignore_warnings = false
        }
      }
    }
    task "grafana" {
      driver = "docker"
      env {
       GF_INSTALL_PLUGINS="grafana-piechart-panel"
       GF_DATE_FORMATS_FULL_DATE="DD-MM-YYYY HH:mm:ss"
       GF_SERVER_HTTP_ADDR="127.0.0.1"
       GF_SERVER_ROOT_URL = "https://grafana.foo.lgian.com"
       GF_AUTH_GENERIC_OAUTH_ENABLED = "true"
       GF_AUTH_GENERIC_OAUTH_NAME = "keycloak"
       GF_AUTH_GENERIC_OAUTH_ALLOW_SIGN_UP = "true"
       GF_AUTH_GENERIC_OAUTH_ALLOW_ASSIGN_GRAFANA_ADMIN = "true"
       GF_AUTH_GENERIC_OAUTH_CLIENT_ID = "grafana"
       GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET = "8iyGRwhKlv2hQW6Atma0jBSynlAiElcK"
       GF_AUTH_GENERIC_OAUTH_EMAIL_ATTRIBUTE_PATH = "email"
       GF_AUTH_GENERIC_OAUTH_SCOPES = "openid email profile offline_access roles"
       GF_AUTH_GENERIC_OAUTH_LOGIN_ATTRIBUTE_PATH = "username"
       GF_AUTH_GENERIC_OAUTH_NAME_ATTRIBUTE_PATH = "full_name"
       GF_AUTH_GENERIC_OAUTH_AUTH_URL = "https://id.foo.lgian.com/realms/master/protocol/openid-connect/auth"
       GF_AUTH_GENERIC_OAUTH_TOKEN_URL = "https://id.foo.lgian.com/realms/master/protocol/openid-connect/token"
       GF_AUTH_GENERIC_OAUTH_API_URL = "https://id.foo.lgian.com/realms/master/protocol/openid-connect/userinfo"
       GF_AUTH_GENERIC_OAUTH_ROLE_ATTRIBUTE_PATH = "contains(roles[*], 'admin') && 'Admin' || contains(realm_access.roles[*], 'editor') && 'Editor' || 'Viewer'"
      }
      config {
        image = "grafana/grafana:9.5.21"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^9\\.\\d+\\.\\d+$"
        }
        # volumes = [
        #   "/zfs/grafana/data:/var/lib/grafana",
        # ]
      }
      // HACK: this matches {{user}}'s id so that grafana is able to write
      // Switch to a "mount" stanza for this
      user = "1000"
    }
  }
}
