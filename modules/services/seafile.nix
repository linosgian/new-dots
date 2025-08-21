{ config, unstablePkgs, lib, ... }:
let
  cfg = config.services.deployedSvcs;
in
{
  services.seafile = {
    enable = true;
    seahubPackage = unstablePkgs.seahub;
    initialAdminPassword = "willchangeonfirstlogin";
    ccnetSettings.General.SERVICE_URL = "https://files.lgian.com";
    adminEmail = "foo@bar.com";
    dataDir = "/zfs/seafile";
    seafileSettings.fileserver = {
      host = "unix:/run/seafile/server.sock";
    };
  };
}
