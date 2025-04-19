job "livesync" {
  datacenters = ["dc1"]
  type = "service"
  group "livesync" {
    count = 1
    restart {
      attempts = 10
      interval = "5m"
      delay = "15s"
      mode = "fail"
    }
    network {
      mode = "bridge"
    }
    service {
      name = "livesync"
      connect {
        sidecar_service{}
      }
      port = "5984"
      task = "livesync-docker"
      address_mode = "alloc"
      tags = [
        "traefik.enable=true",
      ]
    }
    task "couchdb" {
      driver = "docker"
      env {
        COUCHDB_USER="admin"
        COUCHDB_PASSWORD="${livesync_db_password}"
      }
      config {
        image = "couchdb:3.4.3"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d+\\.\\d+\\.\\d+$"
        }
        args = [
        ]
        volumes = [
          "/zfs/livesync/data:/opt/couchdb/data",
          "/zfs/livesync/etc:/opt/couchdb/etc/local.d"
        ]
      }
      resources {
        memory = 512
      }
    }
  }
}
