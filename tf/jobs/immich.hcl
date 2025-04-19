job "immich" {
  datacenters = ["dc1"]
  type = "service"
  group "immich" {
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
      name = "immich"
      port = "2283"
      address_mode = "alloc"
      tags = [
        "traefik.enable=true",
      ]
      connect {
        sidecar_service {}
      }
    }
    task "immich-db" {
      driver = "docker"
      env {
        POSTGRES_DB="immich"
        POSTGRES_USER="immich"
        POSTGRES_PASSWORD="${immich_db_password}"
        POSTGRES_INITDB_ARGS="--data-checksums"
        TZ = "Europe/Athens"
      }
      config {
        image = "tensorchord/pgvecto-rs:pg14-v0.2.1"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^pg14-v\\d+\\.\\d+\\.\\d+$"
        }
        command = "postgres"
        args = [
          "-c", "shared_preload_libraries=vectors.so",
          "-c", "search_path=\"$user\", public, vectors",
          "-c", "logging_collector=on",
          "-c", "max_wal_size=2GB",
          "-c", "shared_buffers=512MB",
          "-c", "wal_compression=on"
        ]
        volumes = [
          "/zfs/immich/db:/var/lib/postgresql/data"
        ]
      }
      resources {
        memory = 1500
      }
    }
    task "immich-ml" {
      driver = "docker"
      env {
        TZ = "Europe/Athens"
        IMMICH_HOST = "localhost"
        TMPDIR = "/tmp"
        MPLCONFIGDIR = "/local/mplconfig"
      }
      config {
        image = "ghcr.io/immich-app/immich-machine-learning:v1.131.3"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^v\\d+\\.\\d+\\.\\d+$"
        }
        volumes = [
          "/zfs/immich/ml/cache/:/cache/"
        ]
      }
      resources {
        memory = 4000
        memory_max = 5000
      }
    }

    task "immich-server" {
      driver = "docker"
      env {
        NODE_ENV = "production"
        REDIS_HOSTNAME = "127.0.0.1"
        TZ = "Europe/Athens"
        IMMICH_TELEMETRY_INCLUDE = "all"
        DB_HOSTNAME="127.0.0.1"
        DB_USERNAME="immich"
        DB_PASSWORD="${immich_db_password}"
        DB_DATABASE_NAME="immich"
      }
      config {
        image = "ghcr.io/immich-app/immich-server:v1.131.3"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^v\\d+\\.\\d+\\.\\d+$"
        }
        args = [
        ]
        volumes = [
          "/zfs/immich/uploads/:/usr/src/app/upload",
          "/zfs/nextcloud/root/data/lgian/files/linos/:/immich-storage/lgian:ro",
          "/zfs/nextcloud/root/data/ilektra/files/p30/:/immich-storage/ilektra/p30:ro",
          "/zfs/nextcloud/root/data/ilektra/files/camera_only/:/immich-storage/ilektra/camera_only:ro",
          "/zfs/nextcloud/root/data/ilektra/files/videos/:/immich-storage/ilektra/videos:ro",
          "/zfs/nextcloud/root/data/ilektra/files/iphones/Iphone8:/immich-storage/ilektra/iphones:ro",
        ]
      }
      resources {
        memory = 1024
        memory_max = 3072
      }
    }

    task "immich-redis" {
      driver = "docker"
      config {
        image = "redis:7.4-alpine"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d+\\.\\d+-alpine$"
        }
        volumes = [
          "/zfs/immich/redis/config/:/etc/redis/",
          "/zfs/immich/redis/data:/data"
        ]
      }
      resources {
        memory = 256
        cpu = 150
      }
    }
  }
}
