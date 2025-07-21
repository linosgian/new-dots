job "traefik" {
  datacenters = ["dc1"]
  type        = "service"
  group "traefik" {
    count = 1
    restart {
      attempts = 10
      interval = "5m"
      delay = "15s"
      mode = "delay"
    }
    network {
      mode = "bridge"
      port "http" {
        to     = 8080
      }
    }
    service {
      name = "traefik-ingress"
      port = "http"

      connect {
        native = true
      }
    }
    task "traefik" {
      driver = "docker"
      env {
        TZ="Europe/Athens"
      }

      config {
        image        = "traefik:v2.11.27"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^v2\\.\\d+\\.\\d+$"
        }
        network_mode = "host"
        args = [
          "--entryPoints.http.address=192.168.2.3:80",
          "--entryPoints.https.address=192.168.2.3:443",
          "--entryPoints.http.transport.respondingTimeouts.readTimeout=600s",
          "--entryPoints.https.transport.respondingTimeouts.readTimeout=600s",
          "--entryPoints.http.transport.respondingTimeouts.writeTimeout=600s",
          "--entryPoints.https.transport.respondingTimeouts.writeTimeout=600s",
          "--entryPoints.http.transport.respondingTimeouts.idleTimeout=600s",
          "--entryPoints.https.transport.respondingTimeouts.idleTimeout=600s",
          "--entryPoints.http_wg.address=10.192.123.1:80",
          "--entryPoints.https_wg.address=10.192.123.1:443",
          "--entryPoints.https.http.tls=true",
          "--entryPoints.https_wg.http.tls=true",
          "--entrypoints.http.http.redirections.entryPoint.to=https",
          "--entrypoints.http_wg.http.redirections.entryPoint.to=https_wg",
          "--providers.file.watch=true",
          "--providers.file.filename=/etc/traefik/traefik-tls.toml",
          "--providers.consulcatalog=true",
          "--metrics=true",
          "--entryPoints.metrics.address=172.26.64.1:8083",
          "--metrics.prometheus=true",
          "--metrics.prometheus.entryPoint=metrics",
          "--metrics.prometheus.addServicesLabels=true",
          "--providers.consulcatalog.connectaware=true",
          "--providers.consulcatalog.connectbydefault=true",
          "--providers.consulcatalog.servicename=traefik-ingress",
          "--providers.consulcatalog.defaultrule=Host(`{{ normalize .Name }}.lgian.com`)",
          "--providers.consulcatalog.prefix=traefik",
          "--providers.consulcatalog.exposedbydefault=false",
          "--providers.consulcatalog.endpoint.address=127.0.0.1:8500",
          "--accesslog=true",
          "--accesslog.format=json",
          "--api=true",
          "--api.dashboard=true",
        ]

        volumes = [
          "local/traefik-tls.toml:/etc/traefik/traefik-tls.toml",
          "/var/lib/acme/lgian.com/fullchain.pem:/cert.pem",
          "/var/lib/acme/lgian.com/key.pem:/privkey.pem"
        ]
      }

      template {
        data = <<EOF
[[tls.certificates]]
   certFile = "/cert.pem"
   keyFile = "/privkey.pem"

## Enables dashboard and puts it behind the `https` entrypoint
[http.routers.websecure]
    rule = "Host(`lb.lgian.com`)"
    entrypoints = ["https", "https_wg"]
    service = "api@internal"
    middlewares = ["bAuth"]
    [http.routers.api.tls]

[http.middlewares.bAuth.basicAuth]
  users = [
    "${traefik_basic_auth}"
  ]
[http.middlewares.traefiksso.forwardAuth]
  address = "http://traefiksso.service.consul:4181/_oauth"
  trustForwardHeader = true
  authResponseHeaders = ["X-Forwarded-For"]
EOF
        destination = "local/traefik-tls.toml"
      }
    }
  }
}
