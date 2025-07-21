job "prometheus" {
  datacenters = ["dc1"]
  type = "service"

  group "prometheus" {
    count = 1
    network {
      mode = "bridge"
      port "prometheus-http" {
        to = 9090
        host_network = "private"
      }
    }

    service {
      name = "prometheus"
      tags = [
        "traefik.enable=true",
        "traefik.http.routers.prometheus.middlewares=traefiksso@file",
        "metrics"
      ]
      port = "prometheus-http"
      address_mode = "alloc"
      check {
        name = "Prometheus healthcheck"
        type = "http"
        path = "/-/healthy"
        port = "prometheus-http"
        interval = "30s"
        timeout = "5s"
      }
      task = "prometheus"
      connect {
        sidecar_service {
          disable_default_tcp_check = true
          proxy {
            upstreams {
              destination_name = "domain-exporter"
              local_bind_port = 9222
            }
            upstreams {
              destination_name = "torrents-exporter"
              local_bind_port = 9223
            }
          }
        }
      }
    }

    service {
      port = "9093"
      name = "alerts"
      connect {
        sidecar_service {
          disable_default_tcp_check = true
          proxy {
            upstreams {
              destination_name = "notifs-bridge"
              local_bind_port = 3001
            }
          }
        }
      }
      address_mode = "alloc"
      task = "alertmanager"
      tags = [
        "traefik.http.routers.alerts.middlewares=traefiksso@file",
        "traefik.enable=true",
      ]
    }

    restart {
      attempts = 3
      delay    = "20s"
      mode     = "delay"
    }
    task "alertmanager" {
      driver = "docker"

      user = "1000"
      template {
        data = <<EOF
${file("${path}/files/prometheus/alertmanager.yml")}

EOF
        destination = "local/alertmanager.yml"
      }
      config {
        image = "prom/alertmanager:v0.28.1"
        labels = {
          "wud.tag.include" = "^v\\d+\\.\\d+\\.\\d+$"
          "wud.watch" = "true"
        }

        args = [
          "--config.file=/etc/alertmanager/alertmanager.yml",
          "--storage.path=/alertmanager",
          "--web.external-url=https://alerts.lgian.com"
        ]

        volumes = [
          "/zfs/alertmanager:/alertmanager",
          "local/alertmanager.yml:/etc/alertmanager/alertmanager.yml",
        ]
      }

      resources {
        memory = 256
      }

    }
    task "prometheus" {
      driver = "docker"

      config {
        image = "prom/prometheus:v3.5.0"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^v\\d+\\.\\d+\\.\\d+$"
        }
        volumes = [
          "local/prometheus.yml:/etc/prometheus/prometheus.yml",
          "local/host.yml:/etc/prometheus/alerts/host.yml",
          "local/records.yml:/etc/prometheus/alerts/records.yml",
          "/zfs/prometheus:/prometheus",
        ]
        args = [
          "--config.file=/etc/prometheus/prometheus.yml",
          "--storage.tsdb.path=/prometheus",
          "--web.console.libraries=/usr/share/prometheus/console_libraries",
          "--web.console.templates=/usr/share/prometheus/consoles",
          "--web.enable-admin-api",
          "--web.external-url=https://prometheus.lgian.com",
          "--storage.tsdb.retention.time=5y",
        ]
      }

      user = "1000"
      template {
        left_delimiter = "[["
        right_delimiter = "]]"
        data = <<EOF
${file("${path}/files/prometheus/prometheus.yml")}

EOF
        destination = "local/prometheus.yml"
        change_mode = "restart"
      }

      template {
        left_delimiter = "[["
        right_delimiter = "]]"
        data = <<EOF
${file("${path}/files/prometheus/records.yml")}

EOF
        destination = "local/records.yml"
        change_mode = "restart"
      }


      template {
        left_delimiter = "[["
        right_delimiter = "]]"
        data = <<EOF
${file("${path}/files/prometheus/alerts.yml")}

EOF
        destination = "local/host.yml"
        change_mode = "restart"
      }

      resources {
        memory = 1024
      }
    }
  }
}
