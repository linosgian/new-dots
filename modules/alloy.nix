{ config, lib, pkgs, ... }:
with lib;
let cfg = config.lg.alloy;
in
{
  options.lg.alloy = {
    enable = mkOption {
      default = false;
    };
    remoteWriteHost = mkOption {
      type = types.str;
      default = "https://prometheus.lgian.com/api/v1/write";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.alloy.environment.HOSTNAME = "%H";
    services.alloy.enable = true;
    environment.etc."alloy/base.alloy" = {
      text = ''
        prometheus.remote_write "prometheus" {
          endpoint {
            url = "${cfg.remoteWriteHost}"
          }
        }
        prometheus.relabel "global_labels" {
          forward_to = [prometheus.remote_write.prometheus.receiver]
          rule {
            target_label = "instance"
            replacement = sys.env("HOSTNAME")
          }
        }

        logging {
          level = "info"
        }
      '';
    };

    environment.etc."alloy/node_exporter.alloy" = {
      text = ''
        prometheus.exporter.unix "node_exporter" {
          enable_collectors = [ "systemd" ]
        }

        prometheus.relabel "node_relabel" {
          forward_to = [
              prometheus.relabel.global_labels.receiver,
          ]
          rule {
            target_label = "job"
            replacement = "node"
          }
        }
        prometheus.scrape "node_exporter" {
          targets    = prometheus.exporter.unix.node_exporter.targets
          scrape_interval = "15s"
          forward_to = [
            prometheus.relabel.node_relabel.receiver,
          ]
        }
      '';
    };
  };
}
