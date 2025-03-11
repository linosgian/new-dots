{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    ../../blueprints/server.nix
    ../../modules/headscale
    ({ config, ... }: {
      headscale.hostname = "connector.lgian.com";
      headscale.v4Prefix = "198.18.4.0/24";
      headscale.acmeEmail = "vaggian1992@gmail.com";
    })
  ];

  networking.hostName = "connector";

  networking.firewall.allowedTCPPorts = [ 22 80 443 9000 ];


  system.stateVersion = "24.11";
}
