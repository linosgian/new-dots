{ config, lib, pkgs, ... }:
let
  cfg = config.services.deployedSvcs;
in
{
  sops.templates."grafana_envs".content = ''
    GF_AUTH_GENERIC_OAUTH_CLIENT_SECRET="${config.sops.placeholder.grafana_oidc_secret}"
  '';
  services.grafana = {
    enable = true;
    dataDir = "/zfs/grafana";
    settings = {
      "auth.generic_oauth" = {
         enabled = true;
         name = "keycloak";
         allow_sign_up = true;
         client_id = "grafana";
         scopes = "openid email profile offline_access roles";
         login_attribute_path = "username";
         name_attribute_path = "full_name";
         auth_url = "https://id.lgian.com/realms/master/protocol/openid-connect/auth";
         token_url = "https://id.lgian.com/realms/master/protocol/openid-connect/token";
         api_url = "https://id.lgian.com/realms/master/protocol/openid-connect/userinfo";

         # Maps roles to Grafana roles
         role_attribute_path =
           "contains(roles[*], 'admin') && 'Admin' || contains(realm_access.roles[*], 'editor') && 'Editor' || 'Viewer'";
      };
      server = {
        root_url = "https://grafana.lgian.com";
        http_port = cfg.defs.grafana.port;
      };
    };
  };

  systemd.services.grafana.serviceConfig.EnvironmentFile = config.sops.templates."grafana_envs".path;
}
