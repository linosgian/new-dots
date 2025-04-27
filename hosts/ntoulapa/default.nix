{ lib, config, pkgs, nixvirt, ...  }:
{
  imports = [
    ../../blueprints/server.nix
    ../../modules/nomad.nix
    ../../modules/consul.nix
    ./hardware-configuration.nix
    ./disko.nix
    ./vms.nix
    ./exporters.nix
    ./networking.nix
    ./certs.nix
  ];

  networking.hostName = "ntoulapa";

  sops = {
    defaultSopsFile = ../../secrets/ntoulapa/secrets.yaml;
    secrets.digitalocean_api_token = {};
    secrets.backblaze_acc_id = {};
    secrets.backblaze_acc_key = {};
    secrets.restic_password = {};
    secrets.restic_password = {};
  };

  sops.templates."restic_envs".content = ''
    B2_ACCOUNT_ID="${config.sops.placeholder.backblaze_acc_id}"
    B2_ACCOUNT_KEY="${config.sops.placeholder.backblaze_acc_key}"
  '';

  sops.templates."acme-do-opts".content = ''
    DO_AUTH_TOKEN=${config.sops.placeholder.digitalocean_api_token}
    DO_PROPAGATION_TIMEOUT=600
    DO_POLLING_INTERVAL=60
  '';

  services.unbound = {
    enable = true;
    enableRootTrustAnchor = false;
    settings = {
      # required for unbound-exporter
      remote-control.control-enable = true;
      server = {
        interface = [ "0.0.0.0" ];
        do-not-query-localhost = false;
        access-control = [
          "127.0.0.1/32 allow"
          "172.26.64.1/24 allow"
        ];
        local-zone = [ "\"id.lgian.com\" transparent" ];
        local-data = [ "\"id.lgian.com. 3600 A 127.0.0.1\"" ];
      };

      forward-zone = [
        { name = "."; forward-addr = "192.168.2.1"; }
        { name = "consul."; forward-addr = "127.0.0.1@8600";  } ];
    };
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

  power.ups = {
    enable = true;

    ups."eaton" = {
      driver = "usbhid-ups";
      port = "auto";
      description = "Eaton UPS";
    };

    users.monitor = {
      passwordFile = "/etc/nixos/upspass";
      upsmon = "primary";
    };

    upsd = {
      enable = true;
      listen = [
        { address = "127.0.0.1"; }
      ];
    };

    upsmon = {
      enable = true;
      monitor.eaton = {
        user = "monitor";
        type = "master";
        powerValue = 1;
      };
    };
  };

  system.stateVersion = "24.11";
}
