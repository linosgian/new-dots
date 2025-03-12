{ config, pkgs, ... }:
{
  services.consul = {
    enable = true;
    package = pkgs.consul;
    webUi = true;
    extraConfig = {
      data_dir = "/var/lib/consul";
      bind_addr = "0.0.0.0";
      client_addr = "0.0.0.0";

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
  services.dnsmasq = {
    enable = true;
    settings = {
      listen-address = "0.0.0.0";
      bind-interfaces = true;
    };
    resolveLocalQueries = true;
    settings.server= [
      "/consul/127.0.0.1#8600"
    ];
  };
  systemd.services.consul = {
    wantedBy = [ "multi-user.target" ];
  };
}

