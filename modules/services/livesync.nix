{ config, ... }:
let
  cfg = config.services.deployedSvcs;
in
{
  services.couchdb = {
    enable = true;
    port = cfg.defs.livesync.port;
    configFile = "/zfs/livesync/etc/docker.ini";
    databaseDir = "/zfs/livesync";
  };
}
