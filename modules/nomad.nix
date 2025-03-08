{ lib, config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    damon # TUI for Nomad.
  ];

  virtualisation.docker.daemon.settings = {
    "dns" = ["172.26.64.1"];
  };
  services.nomad = {
    enable = true;
    package = pkgs.nomad;
    extraPackages = [
      pkgs.cni-plugins
      pkgs.consul
    ];
    dropPrivileges=false;
    settings = {
      data_dir = "/var/lib/nomad";
      bind_addr = "0.0.0.0";
      plugin = {
        docker = {
          extra_labels = ["job_name" "task_name"];
          allow_caps = ["audit_write" "chown" "dac_override" "fowner" "fsetid" "kill" "mknod" "net_bind_service" "setfcap" "setgid" "setpcap" "setuid" "sys_chroot" "net_raw"];
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
        cni_path = "${pkgs.cni-plugins}/bin";
        options = {
          "docker.volumes.enabled" = "true";
        };
      };
    };
    enableDocker = true;
  };

  systemd.services.nomad = {
    requires = [ "consul.service" ];
  };

}
