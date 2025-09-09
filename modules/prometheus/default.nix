{
  lib,
  config,
  pkgs,
  unstablePkgs,
  ...
}:
{
  services.prometheus = {
    enable = true;
    port = 9090;
    extraFlags = [
      "--web.enable-remote-write-receiver"
    ];
    webExternalUrl = "https://prometheus.lgian.com";
    retentionTime = "5y";
    stateDir = "prometheus";
    scrapeConfigs = [
      {
        job_name = "router";
        scrape_interval = "5s";
        static_configs = [
          {
            targets = [
              "router.lgian.com:9100"
              "router.lgian.com:9167"
              "router.lgian.com:9374"
            ];
          }
        ];
      }
      {
        job_name = "smartplugz";
        scrape_interval = "5s";
        static_configs = [
          {
            targets = [
              "sp-washer.lan"
              "sp-ntoulapa.lan"
              "sp-aircnd-bedroom.lan"
              "sp-aircnd-pcroom.lan"
              "sp-fridge.lan"
              "sp-heater.lan"
              "sp-dishwasher.lan"
              "sp-linos-desktop.lan"
            ];
          }
        ];
      }
    ];

    rules = import ./rules.nix { inherit pkgs; };

    alertmanagers = [
      {
        static_configs = [
          {
            targets = [ "localhost:9093" ];
          }
        ];
      }
    ];

  };

  services.prometheus.alertmanager = {
    enable = true;
    port = 9093;

    extraFlags = [
      "--web.external-url=https://alerts.lgian.com"
    ];
    configuration = {
      route = {
        group_by = [ "alertname" ];
        group_wait = "5s";
        group_interval = "10s";
        repeat_interval = "30m";
        receiver = "ntfy";

        routes = [
          {
            matchers = [
              "service = gateway"
              "severity = major"
            ];
            receiver = "ntfy";
          }
        ];
      };

      inhibit_rules = [
        {
          source_match = {
            severity = "critical";
          };
          target_match = {
            severity = "warning";
          };
          equal = [ "alertname" ];
        }
      ];

      receivers = [
        {
          name = "ntfy";
          webhook_configs = [
            { url = "http://127.0.0.1:3001/hook"; }
          ];
        }
      ];
    };
  };

  systemd.services.prometheus.serviceConfig = {
    WorkingDirectory = lib.mkForce "/var/lib/prometheus/data";
    StateDirectory = lib.mkForce "/var/lib/prometheus/data";
  };

  systemd.services.prometheus.serviceConfig.BindPaths = [
    "/ssd-new/prometheus/data:/var/lib/prometheus/data/"
  ];
}
