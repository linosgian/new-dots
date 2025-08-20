{ config, lib, ... }:
let
  cfg = config.services.deployedSvcs;
in
{
  services.radarr = {
    enable = true;
    group = "media";
    settings.server = {
      port = cfg.defs.radarr.port;
      bindaddress = "127.0.0.1";
    };
    dataDir = "/zfs/radarr-new/config";
  };
}
