{
  lib,
  config,
  pkgs,
  unstablePkgs,
  nixvirt,
  ...
}:
{
  imports = [
    ../../blueprints/server.nix
    ../../modules/alloy.nix
    ../../modules/prometheus/default.nix
    ../../modules/prometheus/ntfy.nix
    ../../modules/nostos
    ./hardware-configuration.nix
    ./disko.nix
    ./exporters.nix
    ./networking.nix
    ./certs.nix
    ./services.nix
    ./alloy.nix
    ./containers.nix
  ];

  networking.hostName = "ntoulapa";

  sops = {
    defaultSopsFile = ../../secrets/ntoulapa/secrets.yaml;
    secrets.digitalocean_api_token = { };
    secrets.backblaze_acc_id = { };
    secrets.backblaze_acc_key = { };
    secrets.restic_password = { };
    secrets.restic_password = { };
    secrets.grafana_oidc_secret = { };
    secrets.keycloak_db_password = { };
    secrets.ntfy_user_password = { };
    secrets.deluge_admin_password = { };
    secrets.deluge_user_password = { };
  };

  sops.templates."alertmanager-ntfy".content = ''
    ntfy:
      auth:
        basic:
          username: notifs
          password: ${config.sops.placeholder.ntfy_user_password}
  '';
  sops.templates."keycloak_db_password".content = ''
    ${config.sops.placeholder.keycloak_db_password}
  '';
  sops.templates."deluge_auth_file".content = ''
    admin:${config.sops.placeholder.deluge_admin_password}:10
    localclient:${config.sops.placeholder.deluge_user_password}:10
  '';
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
        interface = [ "127.0.0.1" ];
        do-not-query-localhost = false;
      };

      forward-zone = [
        {
          name = ".";
          forward-addr = "192.168.2.1";
        }
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    restic
  ];

  sops.templates."ddns-config".content = ''
    {
      "settings": [
        {
          "provider": "digitalocean",
          "domain": "hm.lgian.com",
          "token": "${config.sops.placeholder.digitalocean_api_token}",
          "ip_version": "ipv4"
        }
      ]
    }
  '';
  environment.etc."ddns-config".source = config.sops.templates."ddns-config".path;
  services.ddns-updater = {
    enable = true;
    package = unstablePkgs.ddns-updater;
    environment = {
      RESOLVER_ADDRESS = "1.1.1.1:53";
      CONFIG_FILEPATH = "%d/conf";
    };
  };
  systemd.services.ddns-updater.serviceConfig.LoadCredential = "conf:/etc/ddns-config";
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

  system.stateVersion = "25.05";
}
