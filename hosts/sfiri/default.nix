{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../blueprints/server.nix
    ../../modules/alloy.nix
    ./cups.nix
    ./klipper.nix
    ./hardware-configuration.nix
  ];
  networking.hostName = "sfiri";

  lg.alloy.enable = true;
  sops = {
    defaultSopsFile = ../../secrets/home/secrets.yaml;
    secrets.digitalocean_api_token = { };
    secrets.tenta = { };
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

  sops.templates."psk".content = ''
    tenta=${config.sops.placeholder.tenta}
  '';

  networking.networkmanager.enable = false;
  networking.firewall.allowedTCPPorts = [
    22
    80
    443
  ];
  system.stateVersion = "25.05"; # DO NOT CHANGE ME
}
