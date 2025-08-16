{ lib, pkgs, ... }:
let
  vaultwardenPort = 8999;
in
{
  services.vaultwarden = {
    enable = true;
    config = {
      ROCKET_PORT = vaultwardenPort;
      WEBSOCKET_ENABLED = true;
      SIGNUPS_ALLOWED = false;
      DATA_FOLDER = "/zfs/vaultwarden";
    };
  };
  systemd.services.vaultwarden.serviceConfig.ReadWritePaths = [
    "/zfs/vaultwarden"
  ];
}
