{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{

  imports = [
    ../../blueprints/server.nix
    ../../modules/nomad.nix
    ../../modules/consul.nix
    ./hardware-configuration.nix
    ./disko.nix
  ];

  networking.hostName = "ntoulapa";


    };
  };

  sops = {
    defaultSopsFile = ../../secrets/ntoulapa/secrets.yaml;
    secrets.digitalocean_api_token = {};
    secrets.backblaze_acc_id = {};
    secrets.backblaze_acc_key = {};
    secrets.restic_password = {};
  };

  sops.templates."restic_envs".content = ''
    B2_ACCOUNT_ID="${config.sops.placeholder.backblaze_acc_id}"
    B2_ACCOUNT_KEY="${config.sops.placeholder.backblaze_acc_key}"
  '';

  networking.vlans.vlan106 = {
    id = 106;
    interface = "enp7s0";
  };

  networking.bridges = {
    "br-vlan106" = {
      interfaces = [ "vlan106" ];
    };
  };

  networking.dhcpcd.denyInterfaces = [ "veth*" ];

  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    settings.server= [
      "/.consul/127.0.0.1#8600"
      "192.168.2.1"
    ];
  };

  environment.systemPackages = with pkgs; [
    restic
  ];
  services.restic.backups.ntoulapa = {
    repository = "b2:ntoulapa:ntoulapa";
    initialize = false;
    passwordFile = config.sops.secrets.restic_password.path;
    environmentFile = config.sops.templates."restic_envs".path;
    paths = [ 
      "/zfs/nextcloud/root/data/ilektra/files/"
      "/zfs/nextcloud/root/data/lgian/files/linos/"
      "/zfs/grafana/data/grafana.db"
      "/zfs/nextcloud/root/data/mama/files/photos/"
      "/zfs/immich/uploads/upload"
    ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    pruneOpts = [
      "--keep-last 3"
      "--keep-monthly 3"
      "--prune"
    ];
  };

  services.prometheus.exporters.restic= {
    enable = true;
    repository = "b2:ntoulapa:ntoulapa";
    passwordFile = config.sops.secrets.restic_password.path;
    environmentFile = config.sops.templates."restic_envs".path;
    refreshInterval = 10800; # 3 hours
    listenAddress = "172.26.64.1";
  };
  security.acme.defaults.email = "linosgian00@gmail.com";
  security.acme.acceptTerms = true;
  security.acme.certs."lgian.com" = {
    domain = "*.lgian.com";
    dnsProvider = "digitalocean";
    dnsPropagationCheck = true;
    environmentFile = config.sops.templates."acme-do-opts".path;
  };
  sops.templates."acme-do-opts".content = ''
    DO_AUTH_TOKEN=${config.sops.placeholder.digitalocean_api_token}
    DO_PROPAGATION_TIMEOUT=600
    DO_POLLING_INTERVAL=60
  '';

  networking.firewall.interfaces."enp7s0".allowedTCPPorts = [ 22 80 443  4646 8500 514 ];
  networking.firewall.interfaces."wg0".allowedTCPPorts = [ 22 80 443  4646 8500 514 ];
  networking.firewall.interfaces."nomad".allowedTCPPorts = [ 9633 9100 9753 8083 9374 ];

  networking.firewall.interfaces."nomad".allowedUDPPorts = [ 53 ];
  networking.firewall.interfaces."docker".allowedUDPPorts = [ 53 ];
  networking.firewall.interfaces."enp7s0".allowedUDPPorts = [ 51820 ];

  # This is necessary so that cross-network traffic is allowed to reach my VMs
  networking.firewall.checkReversePath = "loose";


  services.rsyslogd = {
    enable = true;

    extraConfig = ''
      $AllowedSender TCP, 192.168.2.1
      $AllowedSender TCP, 192.168.2.202
      $template RemoteLogs,"/var/log/%HOSTNAME%/%PROGRAMNAME%.log"
      if $fromhost-ip startswith "192.168.2" then ?RemoteLogs
      & stop

      module(load="imtcp")
      input(type="imtcp" port="514" Address="192.168.2.3")
    '';
  };

  system.stateVersion = "24.11";
}
