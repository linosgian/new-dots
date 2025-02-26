{config, pkgs, ... }:
{
  nixpkgs.overlays =[
    (final: prev: {
      klipper-firmware = prev.klipper-firmware.overrideAttrs (old: {
        installPhase = ''
          mkdir -p $out
          cp ./.config $out/config
          cp -r out/* $out
        '';
      });
    })
  ];

  services.moonraker = {
    enable = true;
    allowSystemControl = true;
    settings = {
      file_manager = {
        enable_object_processing = true;
        check_klipper_config_path = false;
      };
      history = {};
      server = { host = "0.0.0.0"; };
      authorization = { 
        cors_domains = [ "*" ];
        force_logins = true;
        trusted_clients = ["127.0.0.1/32"];
      };
    };
  };

  systemd.services.moonraker.restartTriggers = [config.environment.etc."moonraker.cfg".source];
  services.klipper = {
    mutableConfig = true;
    enable = true;
    firmwares = {
      mcu = {
        enable = true;
        enableKlipperFlash = true;
        serial = "/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0 ";
        configFile = ./klipper-build-config;
      };
    };
    configFile = ./printer.cfg;
  };
  systemd.services.moonraker.serviceConfig.SupplementaryGroups = "klipper";


  services.fluidd = {
    enable = true;
    nginx = {
      useACMEHost = "sfiri.lgian.com";
      forceSSL = true;
    };
  };

  users.users.nginx.extraGroups = [ "acme" ];

  security.acme.defaults.email = "linosgian00@gmail.com";
  security.acme.acceptTerms = true;
  security.acme.certs."sfiri.lgian.com" = {
    domain = "sfiri.lgian.com";
    dnsProvider = "digitalocean";
    dnsPropagationCheck = true;
    #TODO: sops
    environmentFile = "${pkgs.writeText "do-creds" ''
      DO_AUTH_TOKEN=dop_v1_5be6c5fd53f9195685d8433950d70845b91007c998453798fd99ba7cc038cd97
      DO_PROPAGATION_TIMEOUT=600
      DO_POLLING_INTERVAL=60
    ''}";
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
