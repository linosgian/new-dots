{ config
, lib
, pkgs
, ...
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
    secrets.digitalocean_api_token = { };
  };

  environment.systemPackages = with pkgs; [
    blog
  ];

  networking.hostName = "okeanos";

  networking.firewall.allowedTCPPorts = [ 22 80 443 5201 5202 ];

  services.nginx.enable = true;
  services.nginx.virtualHosts."blog.lgian.com" = {
    forceSSL = true;
    enableACME = false;
    useACMEHost = "blog.lgian.com";
    root = "${blog}/";
  };

  users.users.nginx.extraGroups = [ "acme" ];
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

  services.tailscale.enable = true;

  services.jellyfin = {
    enable = true;
    dataDir = "/var/lib/jellyfin/config";
    cacheDir = "/var/lib/jellyfin/cache/";
    configDir = "/var/lib/jellyfin/config/config";
  };

  users.users.lgian.extraGroups = [ "jellyfin" ];
  users.users.ntoulapa = {
    isNormalUser = true;
    home = "/home/ntoulapa";
    shell = pkgs.bash;
    extraGroups = [ "users" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBFtRtZWyCsguvCp/xvN6SUitWGb5HMIu4YOZD7Z9BJP backups@okeanos"
    ];
  };
  services.openssh.settings.AllowUsers = lib.mkAfter [ "ntoulapa" ];


  system.stateVersion = "25.05";
}
