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
  services.home-assistant = {
    enable = true;
    configDir = "/zfs/homeassistant-nixos";
    extraComponents = [
      "roborock"
      "radio_browser"
      "tasmota"
      "mobile_app"
      "github"
    ];
    config = {
      http = {
        use_x_forwarded_for = true;
        trusted_proxies = [
          "127.0.0.1"
        ];
        server_port = cfg.defs.homeassistant.port;
        server_host = "127.0.0.1";
      };
    };
  };

  systemd.services.grafana.serviceConfig.EnvironmentFile = config.sops.templates."grafana_envs".path;
}
