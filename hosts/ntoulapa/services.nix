{ lib, pkgs, ... }:
let
  # TODO: convert vaultwarden to a module and don't repeat this port here
  vaultwardenPort = 8999;
  recipesPort = 9000;
  services = {
    pass = { port = vaultwardenPort; host = "pass"; };
    recipes = { port = recipesPort; host = "recipes"; };
  };
   mkVhost = name: { port, host }: {
    "${host}" = {
      serverName = "${host}.lgian.com";
      forceSSL = true;
      enableACME = false;
      useACMEHost = "lgian.com";
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString port}";
      };
    };
  };
in
{
  imports = [
    ../../modules/services/vaultwarden.nix
    ../../modules/services/recipes.nix
  ];
  services.nginx = {
    enable = true;
    virtualHosts = lib.mkMerge (lib.mapAttrsToList mkVhost services ++[
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

}
