{ config, pkgs, ... }:
{
  nixpkgs.overlays = [
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
      history = { };
      server = { host = "0.0.0.0"; };
      authorization = {
        cors_domains = [ "*" ];
        force_logins = true;
        trusted_clients = [ "127.0.0.1/32" ];
      };
    };
  };

  systemd.services.moonraker.restartTriggers = [ config.environment.etc."moonraker.cfg".source ];
  services.klipper = {
    mutableConfig = true;
    enable = true;
    firmwares = {
      mcu = {
        enable = true;
        enableKlipperFlash = true;
        serial = "/dev/serial/by-id/usb-1a86_USB_Serial-if00-port0";
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
      extraConfig = ''
        client_max_body_size 200M;
      '';
    };
  };

  users.users.nginx.extraGroups = [ "acme" ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
