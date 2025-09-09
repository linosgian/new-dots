{ config
, lib
, pkgs
, modulesPath
, unstablePkgs
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

  services.tailscale = {
    enable = true;
    # NOTE: Remove this once https://github.com/NixOS/nixpkgs/issues/438765 is fixed on 25.05
    package = unstablePkgs.tailscale;
    interfaceName = "userspace-networking";
  };

  services.jellyfin = {
    enable = true;
    dataDir = "/var/lib/jellyfin/data";
    cacheDir = "/var/lib/jellyfin/cache";
    configDir = "/var/lib/jellyfin/config";
  };

  networking.useHostResolvConf = false;
  networking.interfaces.eth1 = {
    useDHCP = false;
    ipv4.addresses = [
      {
        address = "192.168.5.3";
        prefixLength = 24;
      }
    ];
  };
  networking.defaultGateway.interface = "eth1";
  networking.defaultGateway.address = "192.168.5.1";

  system.stateVersion = "25.05";
}
