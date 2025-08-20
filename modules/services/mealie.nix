{ config, lib, pkgs, ... }:
let
  cfg = config.services.deployedSvcs;
in
{
  services.mealie = {
    enable = true;
    port = cfg.defs.mealie.port;
    listenAddress = "127.0.0.1";
    settings = {
      RECIPE_PUBLIC = true;
      RECIPE_SHOW_NUTRITION = true;
      RECIPE_SHOW_ASSETS = true;
      RECIPE_LANDSCAPE_VIEW = true;
      RECIPE_DISABLE_COMMENTS = false;
      RECIPE_DISABLE_AMOUNT = false;
      DATA_DIR="/zfs/mealie";
    };
  };

  systemd.services.mealie.serviceConfig.DynamicUser = lib.mkForce false;
  users.users.mealie = {
    group = "mealie";
    isSystemUser = true;
  };
  users.groups.mealie = { };
}
