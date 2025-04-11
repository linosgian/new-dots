{
  config,
  lib,
  pkgs,
  ...
}:
let
    blog = import ../../pkgs/blog { inherit lib pkgs; };
in
{
  imports = [
    ./hardware-configuration.nix
    ../../blueprints/server.nix
  ];
  sops = {
    defaultSopsFile = ../../secrets/digitalocean/secrets.yaml;
    secrets.digitalocean_api_token = {};
  };

  environment.systemPackages = with pkgs; [
    blog
  ];

  networking.hostName = "okeanos";

  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  services.nginx.enable = true;
  services.nginx.virtualHosts."blog.lgian.com" = {
    forceSSL = false;
    enableACME = false;
    root = "${blog}/";
  };

  security.acme.defaults.email = "linosgian00@gmail.com";
  security.acme.acceptTerms = true;
  security.acme.certs."blog.lgian.com" = {
    extraDomainNames = [
      "lgian.com"
    ];
    dnsProvider = "digitalocean";
    dnsPropagationCheck = true;
    environmentFile = config.sops.templates."acme-do-opts".path;
  };

  sops.templates."acme-do-opts".content = ''
    DO_AUTH_TOKEN=${config.sops.placeholder.digitalocean_api_token}
    DO_PROPAGATION_TIMEOUT=600
    DO_POLLING_INTERVAL=60
  '';


  system.stateVersion = "24.11";
}
