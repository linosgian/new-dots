{
  config,
  pkgs,
  lib,
  ...
}:

let
  cintaye = pkgs.callPackage ../../pkgs/cintaye/backend.nix { };
  cintaye-frontend = pkgs.callPackage ../../pkgs/cintaye/frontend.nix { };
  port = 9014;
  dataDir = "/var/lib/cintaye";
in
{
  systemd.services.cintaye = {
    description = "Cintaye recipe backend";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    environment = {
      DB_PATH = "${dataDir}/cintaye.db";
      IMAGES_DIR = "${dataDir}/images";
      ADDR = ":${toString port}";
    };

    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      StateDirectory = "cintaye";
      WorkingDirectory = dataDir;
      ExecStart = "${cintaye}/bin/cintaye";
      Restart = "always";
    };
  };

  # mkVhost in services.nix only handles simple reverse-proxy cases; cintaye
  # needs split routing: static SPA for everything except /api/ and /images/.
  # root must be at server level so the tryFiles /index.html internal redirect
  # still resolves against the correct document root.
  services.nginx.virtualHosts."kitchen" = {
    serverName = "kitchen.lgian.com";
    forceSSL = true;
    enableACME = false;
    useACMEHost = "kitchen.lgian.com";
    root = "${cintaye-frontend}";
    locations = {
      "/" = {
        tryFiles = "$uri $uri/ /index.html";
      };
      "/api/" = {
        proxyPass = "http://127.0.0.1:${toString port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
        extraConfig = ''
          client_max_body_size 50M;
        '';
      };
      "/images/" = {
        proxyPass = "http://127.0.0.1:${toString port}";
        recommendedProxySettings = true;
      };
    };
  };
}
