{ config, pkgs, ... }:
let
  cfg = config.services.deployedSvcs;
in
{
  services.postgresql = {
    enable = true;
    dataDir = "/zfs/keycloak-new/pgdata";
  };

  services.keycloak = {
    enable = true;
    database.port = 5432;
    database.passwordFile = config.sops.templates."keycloak_db_password".path;
    settings = {
      proxy-headers = "xforwarded";
      http-enabled = true;
      http-port = cfg.defs.keycloak.port;
      hostname = "id.lgian.com";
    };
  };
}
