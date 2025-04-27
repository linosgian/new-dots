{ config, pkgs, ... }:
{
  imports = [
    ../../blueprints/server.nix
    ./hardware-configuration.nix
    ../../modules/tailhub
    ../../modules/headscale
    {
      headscale.hostname = "headscale.lgian.com";
      headscale.v4Prefix = "198.18.0.0/24";
    }
  ];
  networking.hostName = "headscale";

  networking.firewall.allowedTCPPorts = [ 22 80 443 9000 ];

  system.stateVersion = "24.11";
}
