{ lib, config, pkgs, nixvirt, ... }:
let
  exporterBindAddr = "172.26.64.1";
  exportersAfterNomad = [
    "node"
    "nut"
    "restic"
    "smartctl"
    "unbound"
    "smokeping"
  ];

  exporterOverrides = lib.genAttrs
    (map (name: "prometheus-${name}-exporter") exportersAfterNomad)
    (name: {
      serviceConfig = {
        Restart = "on-failure";
        RestartSec = "5s";
        StartLimitIntervalSec = 300;
        StartLimitBurst = 5;
      };
      after = [ "nomad.service" ];
      requires = [ "nomad.service" ];
    });
in
{
  services.prometheus.exporters.unbound = {
    enable = true;
    listenAddress = exporterBindAddr;
  };

  services.prometheus.exporters.restic = {
    enable = true;
    repository = "b2:ntoulapa:ntoulapa";
    passwordFile = config.sops.secrets.restic_password.path;
    environmentFile = config.sops.templates."restic_envs".path;
    refreshInterval = 10800; # 3 hours
    listenAddress = exporterBindAddr;
  };

  services.prometheus.exporters.node.listenAddress = exporterBindAddr;
  services.prometheus.exporters.smartctl = {
    enable = true;
    listenAddress = exporterBindAddr;
  };
  services.prometheus.exporters.smokeping = {
    enable = true;
    listenAddress = exporterBindAddr;
    # buckets = "0.001,0.0032,0.0064,0.0128,0.0256,0.03556,0.0452,0.0512,0.0620,0.07,0.08,0.090,0.1024";
    hosts = [
      "router.lgian.com"
      "google.com"
      "ntua.gr"
      "doh.libredns.gr"
      "skroutz.gr"
      "80.106.125.101"
      "ae1.er01.sof01.riotdirect.net"
      "1.1.1.1"
      "8.8.8.8"
      "github.com"
    ];
  };

  services.prometheus.exporters.nut = {
    enable = true;
    listenAddress = exporterBindAddr;
    port = 9199;
    nutVariables = [
      "battery.runtime"
      "battery.status"
      "battery.charge"
      "battery.voltage"
      "battery.voltage.nominal"
      "input.voltage"
      "input.voltage.nominal"
      "ups.load"
      "ups.status"
      "ups.test.interval"
      "ups.test.result"
      "ups.test.date"
    ];
  };

  systemd.services = exporterOverrides;
}
