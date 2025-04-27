{ config
, lib
, pkgs
, modulesPath
, ...
}:
{
  imports = [
    ../../blueprints/server.nix
    ./hardware-configuration.nix
  ];
  networking.nameservers = [ "1.1.1.1" ];

  networking.hostName = "cine";
  networking.useDHCP = lib.mkDefault true;
  networking.firewall.allowedTCPPorts = [ 22 80 9100 ];
  networking.firewall.allowedUDPPorts = [ 41641 ];
  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    virtualHosts."_" = {
      locations."/" = {
        proxyPass = "http://127.0.0.1:8096/";
        proxyWebsockets = true;
      };
    };
  };

  services.tailscale.enable = true;

  services.jellyfin = {
    enable = true;
    dataDir = "/var/lib/jellyfin/data";
    cacheDir = "/var/lib/jellyfin/cache";
    configDir = "/var/lib/jellyfin/config";
  };

  system.stateVersion = "24.11";
}
