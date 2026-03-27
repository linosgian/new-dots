{
  unstable,
  config,
  pkgs,
  unstablePkgs,
  ...
}:
let
  cfg = config.services.deployedSvcs;
in
{
  services.postgresql = {
    package = unstablePkgs.postgresql_16;
    enable = true;
    ensureDatabases = [ "immich" ];
    dataDir = "/ssd-new/immich-db/pgdata";
    ensureUsers = [
      {
        name = "immich";
        ensureDBOwnership = true;
        ensureClauses.login = true;
      }
    ];
    extensions =
      ps: with ps; [
        vectorchord
        pgvector
      ];
    settings = {
      shared_preload_libraries = [
        "vchord.so"
      ];
      search_path = "\"$user\", public, vectors";
    };
  };

  services.immich = {
    package = unstablePkgs.immich;
    enable = true;
    port = cfg.defs.immich.port;
    host = "127.0.0.1";
    database.createDB = false;
    database.enableVectors = false;
    accelerationDevices = [
      "/dev/dri/renderD128"
    ];
    mediaLocation = "/usr/src/app/upload";
  };

  # Maintain the old docker paths to avoid migrating
  systemd.services.immich-server.serviceConfig.BindPaths = [
    "/zfs/immich/uploads/:/usr/src/app/upload"
    "/ssd-new/immich-thumbs/thumbs:/usr/src/app/upload/thumbs"
    "/zfs/immich/config/:/config"
    "/zfs/nextcloud/root/data/lgian/files/linos/:/immich-storage/lgian"
    "/zfs/nextcloud/root/data/ilektra/files/p30/:/immich-storage/ilektra/p30"
    "/zfs/nextcloud/root/data/ilektra/files/camera_only/:/immich-storage/ilektra/camera_only"
    "/zfs/nextcloud/root/data/ilektra/files/videos/:/immich-storage/ilektra/videos"
    "/zfs/nextcloud/root/data/ilektra/files/iphones/Iphone8:/immich-storage/ilektra/iphones"
  ];
}
