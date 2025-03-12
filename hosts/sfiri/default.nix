{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../blueprints/server.nix
    ./cups.nix
    ./klipper.nix
  ];
  networking.hostName = "sfiri";

  sops = {
    defaultSopsFile = ../../secrets/digitalocean/secrets.yaml;
    secrets.digitalocean_api_token = {};
  };

  security.acme.defaults.email = "linosgian00@gmail.com";
  security.acme.acceptTerms = true;
  security.acme.certs."sfiri.lgian.com" = {
    domain = "sfiri.lgian.com";
    dnsProvider = "digitalocean";
    dnsPropagationCheck = true;
    environmentFile = config.sops.templates."acme-do-opts".path;
  };

  sops.templates."acme-do-opts".content = ''
    DO_AUTH_TOKEN=${config.sops.placeholder.digitalocean_api_token}
    DO_PROPAGATION_TIMEOUT=600
    DO_POLLING_INTERVAL=60
  '';


  networking.networkmanager.enable = false;
  networking.interfaces."wlan0".useDHCP = true;
  networking.wireless = {
    enable = true;
    interfaces = [ "wlan0" ];
    networks."TENTA_5G".psk = "linakoss123";
    extraConfig = "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel";
  };
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  system.stateVersion = "24.11"; # DO NOT CHANGE ME
}
