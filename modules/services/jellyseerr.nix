{ config, lib, ... }:
let
  cfg = config.services.deployedSvcs;
in
{
  services.jellyseerr = {
    enable = true;
    port = cfg.defs.jellyseerr.port;
  };

  systemd.services.jellyseerr.serviceConfig = {
    DynamicUser = lib.mkForce false;
    User = "jellyseerr";
    Group = "media";

    BindPaths = [
      "/zfs/jellyseerr:/var/lib/jellyseerr"
    ];
  };
  users.users.jellyseerr = {
    isSystemUser = true;
    group = "media";
  };
}
