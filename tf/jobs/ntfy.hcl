job "ntfy" {
  datacenters = ["dc1"]
  type = "service"
  group "ntfy" {
    count = 1
    restart {
      attempts = 20
      interval = "30m"
      delay = "5s"
      mode = "fail"
    }
    network {
      mode = "bridge"
    }

    service {
      name = "notifs-bridge"
      port = "8080"
      address_mode = "alloc"
      connect {
        sidecar_service {}
      }
    }

    service {
      name = "notifs"
      port = "80"
      address_mode = "alloc"
      tags = [
        "traefik.enable=true",
      ]
      connect {
        sidecar_service {}
      }
    }
    task "notifs" {
      driver = "docker"
      env {
        TZ = "Europe/Athens"
      }
      config {
        image = "binwiederhier/ntfy:v2.3.1"
        security_opt = [
          "seccomp=unconfined"
        ]
        volumes = [
          "/zfs/ntfy:/etc/ntfy",
        ]
        args = [
          "serve"
        ]
      }
      resources {
        memory = 512
      }
    }
    task "notifs-alertmanager-bridge" {
      driver = "docker"
      env {
        TZ = "Europe/Athens"
      }
      config {
        image = "xenrox/ntfy-alertmanager:0.2.0"
        volumes = [
          "/zfs/ntfy-alertmanager:/etc/ntfy-alertmanager",
        ]
      }
      resources {
        memory = 256
      }
    }
  }
}
