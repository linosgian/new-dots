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
  services.vaultwarden = {
    enable = true;
    config = {
      ROCKET_PORT = cfg.defs.pass.port;
      WEBSOCKET_ENABLED = true;
      SIGNUPS_ALLOWED = false;
      DATA_FOLDER = "/zfs/vaultwarden";
    };
  };
  systemd.services.vaultwarden.serviceConfig.ReadWritePaths = [
    "/zfs/vaultwarden"
  ];
}
