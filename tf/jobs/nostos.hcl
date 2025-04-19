job "stream_recorder" {
  datacenters = ["dc1"]
  type        = "batch"

  periodic {
    cron            = "0 12 * * 1-5"
    prohibit_overlap = true
    time_zone = "Europe/Athens"
  }

  group "stream_recorder_group" {
    network {
      mode = "bridge"
    }
    task "record_stream" {
      driver = "docker"

      user = "1000:1000"
      config {
        image = "linosgian/nostos:v0.1.2"
        volumes = [
          "/zfs/podcasts/podcasts/Kourafelkithra:/podcasts"
        ]
      }

      env {
        STREAM_URL  = "https://rdst.win:48051/"
        OUTPUT_PATH = "/podcasts/"
        RECORDING_DURATION = "1h"
      }

      restart {
        attempts = 0
        mode     = "fail"
      }
    }
  }
}

