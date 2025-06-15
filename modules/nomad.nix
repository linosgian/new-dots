{ lib, config, pkgs, unstablePkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    damon # TUI for Nomad.
  ];

  virtualisation.docker.daemon.settings = {
    "dns" = [ "172.26.64.1" ];
  };
  services.nomad = {
    enable = true;
    package = unstablePkgs.nomad;
    extraPackages = [
      pkgs.cni-plugins
      pkgs.consul
    ];
    dropPrivileges = false;
    settings = {
      data_dir = "/var/lib/nomad";
      bind_addr = "0.0.0.0";
      plugin = {
        docker = {
          config = {
            extra_labels = [ "job_name" "task_name" ];
            allow_caps = [ "audit_write" "chown" "dac_override" "fowner" "fsetid" "kill" "mknod" "net_bind_service" "setfcap" "setgid" "setpcap" "setuid" "sys_chroot" "net_raw" ];
            volumes = {
              enabled = true;
            };
          };
        };
      };

      telemetry = {
        publish_allocation_metrics = true;
        publish_node_metrics = true;
        prometheus_metrics = true;
        collection_interval = "1s";
      };

      server = {
        enabled = true;
        bootstrap_expect = 1;
      };

      client = {
        enabled = true;
        network_interface = "nomad-br0";
        host_network = {
          "private" = {
            interface = "lo";
          };
        };
        cni_path = "${pkgs.cni-plugins}/bin";
        options = {
          "docker.volumes.enabled" = "true";
        };
      };
    };
    enableDocker = true;
  };


  # If nomad starts before docker, the containers won't get the CNI bridge interface
  systemd.services.nomad = {
    serviceConfig.ExecStartPre = "${pkgs.coreutils}/bin/sleep 40";
    serviceConfig.TimeoutStartSec = 60;
  };

  # During shutdown, old CNI allocated IPs are not cleaned up leading to conflicts
  systemd.services.clear-nomad-networks = {
    description = "Clear Nomad CNI reserved IPs";
    after = [ "network.target" ];
    before = [ "nomad.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/rm -rf /var/lib/cni/networks/nomad/*";
      RemainAfterExit = "yes";
    };
    wantedBy = [ "multi-user.target" ];
  };
  systemd.services.nomad = {
    requires = [ "consul.service" ];
  };

}
