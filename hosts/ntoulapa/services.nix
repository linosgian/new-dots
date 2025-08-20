{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.deployedSvcs;
   mkVhost = name: { port, host }: {
    "${host}" = {
      serverName = "${host}.lgian.com";
      forceSSL = true;
      enableACME = false;
      useACMEHost = "lgian.com";
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString port}";
        proxyWebsockets = true;
        recommendedProxySettings = true;
        extraConfig = ''
          client_max_body_size 1024M;
        '';
      };
    };
  };
in
{
  options.services.deployedSvcs.defs = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = {
      pass = { port = 8999; host = "pass"; };
      mealie = { port = 9000; host = "recipes"; };
      audiobookshelf = { port = 9001; host = "podcasts"; };
      bazarr = { port = 9002; host = "subs"; };
      grafana = { port = 9003; host = "grafana"; };
      homeassistant = { port = 9004; host = "assistant"; };
      livesync = { port = 9005; host = "livesync"; };
      sonarr = { port = 9006; host = "series"; };
      radarr = { port = 9007; host = "movies"; };
      jackett = { port = 9008; host = "jackett"; };
      transmission = { port = 9009; host = "torrents"; };
      keycloak = { port = 9010; host = "id"; };
    };
    description = "Custom service definitions shared across modules.";
  };
  imports = [
    ../../modules/services/vaultwarden.nix
    ../../modules/services/mealie.nix
    ../../modules/services/audiobookshelf.nix
    ../../modules/services/bazarr.nix
    ../../modules/services/grafana.nix
    ../../modules/services/homeassistant.nix
    ../../modules/services/livesync.nix
    ../../modules/services/sonarr.nix
    ../../modules/services/radarr.nix
    ../../modules/services/jackett.nix
    ../../modules/services/transmission.nix
    ../../modules/services/keycloak.nix
  ];
  config = {
    services.nginx = {
      enable = true;
      virtualHosts = lib.mkMerge (lib.mapAttrsToList mkVhost cfg.defs ++[
      {
        # TODO: remove this once all services are migrated over to NixOS
        "lgian.com" = {
            locations."/" = {
              proxyPass = "https://192.168.2.3:9443";
              extraConfig = ''
                proxy_set_header Host $host;
                proxy_set_header X-Real-IP $remote_addr;
                proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                proxy_set_header X-Forwarded-Proto https;
              '';
            };
            default = true;
            serverName = "*.lgian.com";
            forceSSL = true;
            enableACME = false;
            useACMEHost = "lgian.com";
          };
      }
      ]
      );
    };
    users.users.nginx.extraGroups = [ "acme" ];
    # Used by sonarr, bazarr, torrent client and jellyfin.
    users.groups.media = { };
  };

}
