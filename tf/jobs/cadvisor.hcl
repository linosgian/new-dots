job "cadvisor" {
  datacenters = ["dc1"]
  type = "service"

  group "monitoring" {
    network {
      port "http" {
        to = "8080"
        host_network = "private"
      }
    }
    restart {
      attempts = 3
      delay    = "20s"
      mode     = "delay"
    }
    task "cadvisor" {
      driver = "docker"
      config {
        image = "gcr.io/cadvisor/cadvisor:v0.52.1"
        labels = {
          "wud.watch" = "true"
          "wud.tag.include" = "^v\\d+\\.\\d+\\.\\d+$"
        }
        ports = [ "http" ]
        args = [
          "--docker_only=true",
          "--housekeeping_interval=30s",
          "--store_container_labels=false",
          "--whitelisted_container_labels=com.hashicorp.nomad.task_name, com.hashicorp.nomad.job_name, com.hashicorp.nomad.alloc_id",
          "--disable_metrics=cpu_topology,disk,memory_numa,tcp,udp,percpu,sched,process,hugetlb,referenced_memory,resctrl,cpuset,advtcp,memory_numa"
        ]
        logging {
          type = "journald"
          config {
            tag = "CADVISOR"
          }
        }
        network_mode = "bridge"
        devices = [
          {
            host_path = "/dev/kmsg"
            container_path = "/dev/kmsg"
            cgroup_permissions = "r"
          }
        ]
        volumes = [
           "/:/rootfs:ro",
           "/var/run:/var/run:ro",
           "/dev/disk:/dev/disk:ro",
           "/sys:/sys:ro",
           "/var/lib/docker/:/var/lib/docker:ro",
           "/var/run/docker.sock:/var/run/docker.sock:ro",
           "/cgroup:/cgroup:ro",
        ]
      }
      service {
        name = "cadvisor"
        port = "http"
        address_mode = "driver"
        check {
          type = "http"
          path = "/metrics"
          interval = "10s"
          timeout = "2s"
        }
      }
    }
  }
}
