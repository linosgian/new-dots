{
  config,
  pkgs,
  lib,
  ...
}:

let
  athinorama = pkgs.callPackage ../../pkgs/athinorama/backend.nix { };
  athinorama-frontend = pkgs.callPackage ../../pkgs/athinorama/frontend.nix { };
in
{
  environment.systemPackages = [
    athinorama
    athinorama-frontend
  ];
  systemd.services.athinorama = {
    description = "Athinorama Backend";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "simple";
      DynamicUser = true;
      StateDirectory = "athinorama";
      WorkingDirectory = "/var/lib/athinorama";
      ExecStart = "${athinorama}/bin/athinorama";
      Restart = "always";
    };
  };
  services.nginx = {
    enable = true;
    virtualHosts."cinema.lgian.com" = {
      forceSSL = true;
      enableACME = false;
      useACMEHost = "cinema.lgian.com";
      locations = {
        "/api/" = {
          proxyPass = "http://127.0.0.1:8080";
          proxyWebsockets = true;
        };
        "/" = {
          root = "${athinorama-frontend}";
          tryFiles = "$uri $uri/ /index.html";
        };
      };
    };
  };
}
