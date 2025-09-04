{ config, pkgs, ... }:
let
  cfg = config.services.deployedSvcs;
in
{
  services.jellyfin = {
    enable = true;
    dataDir = "/config";
    group = "media";
    configDir = "/config/config";
  };

  # Maintain the old docker paths to avoid migrating
  systemd.services.jellyfin.serviceConfig.BindPaths = [
    "/zfs/torrents/complete:/media"
    "/zfs/jellyfin/config:/config"
    "/zfs/ytdl/downloads/movies:/ytdl-singles"
    "/zfs/ytdl/downloads/tv_shows:/ytdl"
  ];

  systemd.services.jellyfin.environment.LIBVA_DRIVER_NAME = "iHD";
}
