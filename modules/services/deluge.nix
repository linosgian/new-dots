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

  sops.templates."deluge_auth_file".owner = "deluge";
  services.deluge = {
    web.enable = true;
    enable = true;
    group = "media";
    declarative = true;
    web.port = cfg.defs.deluge.port;
    authFile = config.sops.templates."deluge_auth_file".path;
    config = {
      download_location = "/zfs/deluge/";
    };
  };
}
