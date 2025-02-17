{ lib, config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    damon # TUI for Nomad.
  ];

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
      plugin.docker = {};

      server = {
        enabled = true;
        bootstrap_expect = 1;
      };

      client = {
        enabled = true;
        cni_path = "${pkgs.cni-plugins}/bin";
      };
    };
    enableDocker = true;
  };

  systemd.services.nomad = {
    requires = [ "consul.service" ];
  };

}
