{ config, lib, ... }:
let
  cfg = config.services.deployedSvcs;
in
{
  services.audiobookshelf = {
    enable = true;
    port = cfg.defs.audiobookshelf.port;
  };

  services.nginx.virtualHosts."podcasts".locations."/".extraConfig = ''
    proxy_hide_header ETag;
    proxy_hide_header Last-Modified;
    proxy_hide_header Cache-Control;
    add_header Cache-Control "no-store";
  '';
  systemd.services.audiobookshelf.serviceConfig = {
    WorkingDirectory = lib.mkForce "/ssd-new/audiobookshelf";
  };
}
