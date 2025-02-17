{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../blueprints/server.nix
    ./hardware-configuration.nix
    ./docker-compose.nix
  ];
  networking.hostName = "test-nix";

  networking.firewall.allowedTCPPorts = [ 22 ];

  system.stateVersion = "24.11"; # DO NOT CHANGE ME
}
