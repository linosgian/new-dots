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

  networking.firewall.allowedTCPPorts = [ 22 9000];

  environment.systemPackages = with pkgs; [
    minio-client
  ];

  services.minio = {
    listenAddress = ":9000";
    enable = true;
    secretKey = "bb6f9e0a160b40e684161ced89c7c29b";
    accessKey = "975ce6607a634611bb89";
  };

  system.stateVersion = "24.11"; # DO NOT CHANGE ME
}
