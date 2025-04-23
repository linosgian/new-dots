{ config, pkgs, ... }:
{
  services.consul = {
    enable = true;
    package = pkgs.consul;
    webUi = true;
    extraConfig = {
      data_dir = "/var/lib/consul";
      bind_addr = "127.0.0.1";
      client_addr = "127.0.0.1";

      server = true;
      bootstrap_expect = 1;
      ports = {
        "grpc" = 8502;
      };
      connect = {
        enabled = true;
      };
    };
  };
  networking.nameservers = [ "127.0.0.1" ];
  systemd.services.consul = {
    wantedBy = [ "multi-user.target" ];
  };
}

