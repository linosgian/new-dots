{
  config,
  pkgs,
  lib,
  ...
}:
{

  environment.systemPackages = with pkgs; [
  ];

  networking.firewall.interfaces."enp2s0".allowedTCPPorts = [
    8080
  ];
  services.mosquitto = {
    enable = true;
    listeners = [
      {
        port = 1883;
        users = {
          zigbee = {
            passwordFile = config.sops.secrets.mqtt_zigbee_password.path;
            acl = [ "readwrite #" ];
          };
          homeassistant = {
            passwordFile = config.sops.secrets.mqtt_homeassistant_password.path;
            acl = [ "readwrite #" ];
          };
        };
      }
    ];
    bridges."remote_inbound" = {
      addresses = [
        {
          address = "192.168.3.4";
          port = 1883;
        }
      ];
      topics = [
        "# in 0 \"\" \"\""
        "cmnd/# out 0 \"\" \"\""
      ];
      settings = {
        # TODO: remove this MQTT instance altogether
        remote_username = "admin";
        remote_password = "2A%q%qSgZD536t^J^";
        cleansession = true;
        start_type = "automatic";
        try_private = true;
      };
    };
  };

  sops.templates.zigbee2mqtt.content = ''
    ZIGBEE2MQTT_CONFIG_MQTT_PASSWORD="${config.sops.placeholder.mqtt_zigbee_password}"
  '';
  sops.templates."mqtt-exporter".content = ''
    MQTT_USERNAME=zigbee
    MQTT_PASSWORD="${config.sops.placeholder.mqtt_zigbee_password}"

  '';

  environment.etc."mqtt-exporter/env".source = config.sops.templates."mqtt-exporter".path;
  services.prometheus.exporters.mqtt = {
    enable = true;

    environmentFile = "/etc/mqtt-exporter/env";
    # Where the exporter listens for Prometheus
    listenAddress = "127.0.0.1";

    # MQTT broker connection (your broker)
    mqttAddress = "localhost";
    port = 9992;

    # Topic path to subscribe to
    mqttTopic = "zigbee2mqtt/+";

    # Optional: ignore topics (like bridge or config messages)
    mqttIgnoredTopics = [
      "zigbee2mqtt/bridge/+" # ignore zigbee2mqtt internal stuff
    ];

    # If you want extra flags like custom naming/labels
    extraFlags = [
      "--topic-label topic"
      "--prometheus-prefix mqtt_"
    ];
  };
  services.zigbee2mqtt = {
    enable = true;
    settings = {
      homeassistant = lib.mkForce true;
      permit_join = false;

      mqtt = {
        server = "mqtt://localhost:1883";
        user = "zigbee";
      };

      serial = {
        port = "/dev/serial/by-id/usb-Itead_Sonoff_Zigbee_3.0_USB_Dongle_Plus_V2_8c76728769f3ef11b6a0bd1b6d9880ab-if00-port0";
        adapter = "ember";
      };

      frontend = {
        enable = true;
        port = 8080;
      };
      advanced = {
        channel = 25;
      };
    };
  };
  systemd.services.zigbee2mqtt.serviceConfig.EnvironmentFile = config.sops.templates.zigbee2mqtt.path;
  users.users.zigbee2mqtt.extraGroups = [ "dialout" ];
}
