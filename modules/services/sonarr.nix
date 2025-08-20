{ config, lib, ... }:
let
  cfg = config.services.deployedSvcs;
in
{
  services.sonarr = {
    enable = true;
    group = "media";
    settings.server = {
      port = cfg.defs.sonarr.port;
      bindaddress = "127.0.0.1";
    };
    dataDir = "/zfs/sonarr/config";
  };
}
