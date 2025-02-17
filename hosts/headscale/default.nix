{config, pkgs, ...}:
{
  imports = [
    ../../blueprints/server.nix
    ./hardware-configuration.nix
    ../modules/tailhub
    ../modules/headscale
    {
      headscale.hostname = "headscale.lgian.com";
      headscale.v4Prefix = "198.18.0.0/24";
    }
  ];
  networking.hostName = "headscale";

  networking.firewall.allowedTCPPorts = [ 22 80 443 9000 ];

  services.prometheus.exporters.node = {
    enable = true;
    port = 9000;
    # https://github.com/NixOS/nixpkgs/blob/nixos-24.05/nixos/modules/services/monitoring/prometheus/exporters.nix
    enabledCollectors = [ "systemd" ];
    # /nix/store/zgsw0yx18v10xa58psanfabmg95nl2bb-node_exporter-1.8.1/bin/node_exporter  --help
    extraFlags = [ "--collector.ethtool" "--collector.softirqs" "--collector.tcpstat" "--collector.wifi" ];
  };
  system.stateVersion = "24.11";
}
