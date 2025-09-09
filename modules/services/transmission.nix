{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.deployedSvcs;
in
{
  services.transmission = {
    package = pkgs.transmission_4;
    enable = true;
    group = "media";
    webHome = pkgs.flood-for-transmission;
    settings = {
      dht-enabled = false;
      download-dir = "/zfs/transmission/downloads/";
      incomplete-dir = "/zfs/transmission/downloads/incomplete";
      rpc-bind-address = "127.0.0.1";
      rpc-port = cfg.defs.transmission.port;
      rpc-authentication-required = false;
      rpc-host-whitelist-enabled = false;
      rpc-whitelist-enabled = false;
    };
  };
}
