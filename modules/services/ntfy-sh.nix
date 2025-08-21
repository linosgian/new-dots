{ config, lib, unstablePkgs, pkgs, ... }:
let
  cfg = config.services.deployedSvcs;
in
{
  services.ntfy-sh = {
    enable = true;
    package = unstablePkgs.ntfy-sh;
    settings = {
      listen-http = "127.0.0.1:${toString cfg.defs.ntfy-sh.port}";
      base-url = "https://notifs.lgian.com";
      auth-default-access = "deny-all";
      cache-duration = "12h";
      auth-users = [
        "lgian:$2y$10$HwPGYnVPWezuHhkUSYVOCeJLx9FotXdNrsY0DS3OkFIqnaIFrEMCe:user"
        "notifs:$2a$10$/SBHKfvs.2DOw/Re7RfEqOFfd3ixufewINA8.kSPLR3URWh/kZGcy:admin"
      ];
      auth-access = [
        "lgian:*:ro"
      ];
    };
  };
}
