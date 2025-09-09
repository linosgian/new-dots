{ config, ... }:
{
  services.prometheus.alertmanager-ntfy = {
    enable = true;
    extraConfigFiles = [
      config.sops.templates."alertmanager-ntfy".path
    ];
    settings = {
      http.addr = "127.0.0.1:3001";
      ntfy = {
        baseurl = "http://127.0.0.1:9011";
        notification.topic = "alertmanager";
      };
    };
  };
}
