{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../blueprints/server.nix
    ./octoprint.nix
    ./cups.nix
  ];
  networking.hostName = "sfiri";

  # networking.networkmanager.enable = false;
  # networking.interfaces."wlan0".useDHCP = true;
  # networking.wireless = {
  # enable = true;
  # interfaces = [ "wlan0" ];
  # networks."TENTA_5G".psk = "xxxxxxxxxxxxx";
  # extraConfig = "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel";
  # };
  services.prometheus.exporters.node = {
    enable = true;
    port = 9000;
    # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/exporters.nix
    enabledCollectors = [ "systemd" ];
    # /nix/store/zgsw0yx18v10xa58psanfabmg95nl2bb-node_exporter-1.8.1/bin/node_exporter  --help
    extraFlags = [ "--collector.ethtool" "--collector.softirqs" "--collector.tcpstat" "--collector.wifi" ];
  };
  networking.firewall.allowedTCPPorts = [ 22 80 443 9000 ];
  services.tailscale.enable = true;
  virtualisation.forwardPorts = [
    {
      from = "host";
      host.port = 2222;
      guest.port = 22;
    }
    {
      from = "host";
      host.port = 8888;
      guest.port = 5000;
    }

    {
      from = "host";
      host.port = 4443;
      guest.port = 443;
    }
    {
      from = "host";
      host.port = 8080;
      guest.port = 80;
    }
    # {
    #   from = "host";
    #   host.port = 631;
    #   guest.port = 631;
    # }
  ];

  system.stateVersion = "24.11"; # DO NOT CHANGE ME
}
