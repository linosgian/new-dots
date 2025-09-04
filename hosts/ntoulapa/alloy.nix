{ config, lib, pkgs, ... }:
{
  lg.alloy.enable = true;
  services.prometheus.exporters.domain = {
    enable = true;
    listenAddress = "127.0.0.1";
  };
  environment.etc."alloy/domain_exporter.alloy" = {
    text = ''
      discovery.relabel "domain_targets" {
        targets = [
          {
            __address__ = "lgian.com",
          },
        ]
        rule {
          source_labels = ["__address__"]
          target_label  = "__param_target"
        }
        rule {
          target_label = "__address__"
          replacement  = "127.0.0.1:9222"
        }
      }
      prometheus.scrape "domain_exporter" {
        targets         = discovery.relabel.domain_targets.output
        forward_to      = [prometheus.relabel.global_labels.receiver]
        metrics_path    = "/probe"
        scrape_interval = "30s"
        scrape_timeout  = "10s"
      }
      '';
  };

  environment.etc."alloy/misc.alloy" = {
    text = ''
      prometheus.scrape "misc_exporters" {
        targets = [
          {"__address__" = "127.0.0.1:9374"},
          {"__address__" = "127.0.0.1:9167"},
          {"__address__" = "127.0.0.1:9633"},
        ]
        forward_to      = [prometheus.relabel.global_labels.receiver]
        scrape_interval = "10s"
      }
      '';
  };
  environment.etc."alloy/blackbox.alloy" = {
    text = ''
      prometheus.exporter.blackbox "main" {
        config = "{ modules: { http_2xx: { prober: http, timeout: 5s } } }"

        target {
          name    = "router"
          address = "https://router.lgian.com"
          module  = "http_2xx"
        }

        target {
          name    = "strovilos"
          address = "https://strovilos.gr"
          module  = "http_2xx"
        }
      }

      discovery.relabel "blackbox" {
        targets = prometheus.exporter.blackbox.main.targets

        rule {
          source_labels = ["__param_target"]
          target_label = "instance"
        }
      }
      prometheus.scrape "blackbox" {
        scrape_interval = "15s"
        targets    = discovery.relabel.blackbox.output
        forward_to = [prometheus.relabel.global_labels.receiver]
      }
      '';
  };
}
