{
  config,
  lib,
  pkgs,
  unstablePkgs,
  ...
}:
let
  cfg = config.services.deployedSvcs;
in
{
  services.home-assistant = {
    enable = true;
    # Remove after 2025.12.3 version is on stable
    package = unstablePkgs.home-assistant;
    configDir = "/zfs/homeassistant-nixos";
    extraComponents = [
      "radio_browser"
      "tasmota"
      "mobile_app"
      "github"
    ];

    extraPackages =
      python3Packages: with python3Packages; [
        python-roborock
      ];
    config = {
      mobile_app = { };
      default_config = { };
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
