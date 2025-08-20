{ config, lib, unstable, pkgs, ... }:
let
  cfg = config.services.deployedSvcs;
in
{
  # NOTE: Delete this once dataDir exists on services.bazarr
  imports = [
    "${unstable}/nixos/modules/services/misc/bazarr.nix"
  ];
  disabledModules = [ "services/misc/bazarr.nix" ];
  services.bazarr = {
    enable = true;
    group = "media";
    listenPort = cfg.defs.bazarr.port;
    dataDir = "/zfs/bazarr/config";
  };
}
