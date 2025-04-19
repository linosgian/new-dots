job "nextcloud" {
  datacenters = ["dc1"]
  type = "service"
  group "nextcloud" {
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
      name = "cloud"
      connect {
        sidecar_service{}
      }
      port = "80"
      task = "nextcloud-docker"
      address_mode = "alloc"
      tags = [
        "traefik.enable=true",
      ]
    }
    task "nextcloud-db" {
      driver = "docker"
      env {
        MYSQL_DATABASE="nextcloud"
        MYSQL_USER="nextcloud"
        MYSQL_ROOT_PASSWORD="${nextcloud_db_root_password}"
        MYSQL_PASSWORD="${nextcloud_db_password}"
      }
      config {
        image = "mariadb:10.5.25"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d+\\.\\d+\\.\\d+$"
        }
        args = [
          "--transaction-isolation=READ-COMMITTED",
          "--binlog-format=ROW",
          "--log-bin=mysqld-bin",
          "--bind-address=127.0.0.1",
        ]
        volumes = [
          "/zfs/nextcloud/db:/var/lib/mysql"
        ]
      }
      resources {
        memory = 512
      }
    }
    task "nextcloud-docker" {
      driver = "docker"
      env {
        REDIS_HOST="localhost"
        REDIS_HOST_PASSWORD="${nextcloud_redis_password}"
        PHP_UPLOAD_LIMIT="4G"
        APACHE_BODY_LIMIT="4073741824"
        MYSQL_DATABASE="nextcloud"
        MYSQL_USER="nextcloud"
        MYSQL_HOST="localhost"
        MYSQL_ROOT_PASSWORD="${nextcloud_db_root_password}"
        MYSQL_PASSWORD="${nextcloud_db_password}"
      }
      config {
        image = "nextcloud:29.0.10-apache"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d+\\.\\d+\\.\\d+-apache$"
        }
        volumes = [
          "local/apache2-ports.conf:/etc/apache2/ports.conf",
          "/zfs/nextcloud/root/:/var/www/html",
        ]
      }
      resources {
        memory_max = 3000
        memory = 1500
      }
      template {
        data = <<EOF
  Listen 127.0.0.1:80
EOF
        destination = "local/apache2-ports.conf"
      }
    }
    task "redis" {
      driver = "docker"
      config {
        image = "redis:7.4-alpine"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d+\\.\\d+-alpine$"
        }
        args = [
          "/etc/redis/redis.conf"
        ]
        volumes = [
          "/zfs/nextcloud/redis/config/:/etc/redis/",
          "/zfs/nextcloud/redis/data:/data"
        ]
      }
      resources {
        memory = 256
      }
    }
    task "nextcloud-docker-cron" {
      driver = "docker"
      config {
        image = "nextcloud:29.0.10-apache"
        entrypoint = ["/cron.sh"]
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^\\d+\\.\\d+\\.\\d+-apache$"
        }
        volumes = [
          "/zfs/nextcloud/root/:/var/www/html",
        ]
      }
      resources {
        memory = 512
      }
    }
  }
}
