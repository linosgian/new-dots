{ config, ... }:
let
  cfg = config.services.deployedSvcs;
in
{
  services.jackett = {
    enable = true;
    port = cfg.defs.jackett.port;
    dataDir = "/zfs/jackett/Jackett";
  };
}
