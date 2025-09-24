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
  services.prowlarr = {
    enable = true;
    settings = {
      server.port = cfg.defs.indexer.port;
    };
  };
}
