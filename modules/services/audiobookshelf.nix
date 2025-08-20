{ config, lib, ... }:
let
  cfg = config.services.deployedSvcs;
in
{
  services.audiobookshelf = {
    enable = true;
    port = cfg.defs.audiobookshelf.port;
  };

  systemd.services.audiobookshelf.serviceConfig = {
    WorkingDirectory = lib.mkForce "/zfs/audiobookshelf";
  };
}
