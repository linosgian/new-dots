{ lib, config, pkgs, nixvirt, ...  }:
let
    # List of prometheus exporters that should start after nomad
  exportersAfterNomad = [
    "node"
    "nut"
    "restic"
    "smartctl"
    "unbound"
    "smokeping"
  ];

  # Create a set of systemd service overrides
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
      requires = [ "nomad.service" ]; # Remove this if you only want ordering, not dependency
    });
in
{

  imports = [
    ../../blueprints/server.nix
    ../../modules/nomad.nix
    ../../modules/consul.nix
    ./hardware-configuration.nix
    ./disko.nix
    ./vms.nix
  ];

  networking.hostName = "ntoulapa";

  virtualisation.libvirt.enable = true;
  virtualisation.libvirtd.qemu.vhostUserPackages = [ pkgs.virtiofsd ];

  sops = {
    defaultSopsFile = ../../secrets/ntoulapa/secrets.yaml;
    secrets.digitalocean_api_token = {};
    secrets.backblaze_acc_id = {};
    secrets.backblaze_acc_key = {};
    secrets.restic_password = {};
  };

  sops.templates."restic_envs".content = ''
    B2_ACCOUNT_ID="${config.sops.placeholder.backblaze_acc_id}"
    B2_ACCOUNT_KEY="${config.sops.placeholder.backblaze_acc_key}"
  '';

  networking.vlans.vlan106 = {
    id = 106;
    interface = "enp7s0";
  };

  networking.bridges = {
    "br-vlan106" = {
      interfaces = [ "vlan106" ];
    };
  };

  networking.dhcpcd.denyInterfaces = [ "veth*" ];

  services.unbound = {
    enable = true;
    enableRootTrustAnchor = false;
    settings = {
      remote-control.control-enable = true;
      server = {
        verbosity = 1;
        interface = [ "0.0.0.0" ];
        do-not-query-localhost = false;
        access-control = [
          "127.0.0.1/32 allow"
          "172.26.64.1/24 allow"
        ];

        local-zone = [ "\"id.lgian.com\" transparent" ];
        local-data = [ "\"id.lgian.com. 3600 A 127.0.0.1\"" ];
      };

      forward-zone = [
        { 
          name = ".";
          forward-addr = "192.168.2.1";
        }
        {
          name = "consul.";
          forward-addr = "127.0.0.1@8600";  # Consul DNS
        }
      ];
    };
  };

  environment.systemPackages = with pkgs; [
    restic
    # required for id.lgian.com ACME postRun
    openjdk
    openssl
  ];
  services.restic.backups.ntoulapa = {
    repository = "b2:ntoulapa:ntoulapa";
    initialize = false;
    passwordFile = config.sops.secrets.restic_password.path;
    environmentFile = config.sops.templates."restic_envs".path;
    paths = [ 
      "/zfs/nextcloud/root/data/ilektra/files/"
      "/zfs/nextcloud/root/data/lgian/files/linos/"
      "/zfs/grafana/data/grafana.db"
      "/zfs/nextcloud/root/data/mama/files/photos/"
      "/zfs/immich/uploads/upload"
    ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    pruneOpts = [
      "--keep-last 3"
      "--keep-monthly 3"
      "--prune"
    ];
  };

  services.prometheus.exporters.unbound = {
    enable = true;
    listenAddress = "172.26.64.1";
  };

  services.prometheus.exporters.restic= {
    enable = true;
    repository = "b2:ntoulapa:ntoulapa";
    passwordFile = config.sops.secrets.restic_password.path;
    environmentFile = config.sops.templates."restic_envs".path;
    refreshInterval = 10800; # 3 hours
    listenAddress = "172.26.64.1";
  };

  security.acme.defaults.email = "linosgian00@gmail.com";
  security.acme.acceptTerms = true;
  security.acme.certs."id.lgian.com" = {
    domain = "id.lgian.com";
    dnsProvider = "digitalocean";
    dnsPropagationCheck = true;
    environmentFile = config.sops.templates."acme-do-opts".path;
    postRun = ''
      CERT_DIR="/var/lib/acme/id.lgian.com"
      KEYCLOAK_CERTS="/var/lib/keycloak/certs"
      PASSWORD="whocares"

      # Create output directory
      mkdir -p $KEYCLOAK_CERTS

      echo "Converting certificates to Java keystore..."

      # Create PKCS12 keystore
      ${pkgs.openssl}/bin/openssl pkcs12 -export \
        -in $CERT_DIR/cert.pem \
        -inkey $CERT_DIR/key.pem \
        -out $KEYCLOAK_CERTS/keystore.p12 \
        -name keycloak \
        -passout pass:$PASSWORD

      # Convert to JKS format
      ${pkgs.jdk}/bin/keytool -importkeystore \
        -srckeystore $KEYCLOAK_CERTS/keystore.p12 \
        -srcstoretype PKCS12 \
        -srcstorepass $PASSWORD \
        -destkeystore $KEYCLOAK_CERTS/keystore.jks \
        -deststoretype JKS \
        -deststorepass $PASSWORD \
        -destkeypass $PASSWORD

      # Create truststore
      ${pkgs.jdk}/bin/keytool -import \
        -file $CERT_DIR/chain.pem \
        -alias root \
        -keystore $KEYCLOAK_CERTS/truststore.jks \
        -storepass $PASSWORD \
        -noprompt

      # Also copy PEM files (for flexibility)
      cp $CERT_DIR/cert.pem $KEYCLOAK_CERTS/tls.crt
      cp $CERT_DIR/key.pem $KEYCLOAK_CERTS/tls.key
      cp $CERT_DIR/chain.pem $KEYCLOAK_CERTS/ca.crt

      # Set proper permissions
      chmod 644 $KEYCLOAK_CERTS/*

      # Clean up temporary files
      rm $KEYCLOAK_CERTS/keystore.p12

      # echo "Restarting Nomad job for Keycloak..."
      # # Restart Nomad job
      # ${pkgs.nomad}/bin/nomad job restart -detach keycloak
    '';
  };
  security.acme.certs."lgian.com" = {
    domain = "*.lgian.com";
    dnsProvider = "digitalocean";
    dnsPropagationCheck = true;
    environmentFile = config.sops.templates."acme-do-opts".path;
  };
  sops.templates."acme-do-opts".content = ''
    DO_AUTH_TOKEN=${config.sops.placeholder.digitalocean_api_token}
    DO_PROPAGATION_TIMEOUT=600
    DO_POLLING_INTERVAL=60
  '';

  networking.firewall.interfaces."enp7s0".allowedTCPPorts = [ 22 80 443 514 ];
  networking.firewall.interfaces."enp7s0".allowedUDPPorts = [ 51820 ];

  networking.firewall.interfaces."wg0".allowedTCPPorts = [ 22 80 443 514 ];

  networking.firewall.interfaces."nomad".allowedTCPPorts = [ 9633 9100 9753 8083 9374 9199 9167 ];
  networking.firewall.interfaces."nomad".allowedUDPPorts = [ 53 ];

  networking.firewall.interfaces."docker".allowedUDPPorts = [ 53 ];

  # This is necessary so that cross-network traffic is allowed to reach my VMs on VLAN106
  networking.firewall.checkReversePath = "loose";

  networking.wg-quick.interfaces = {
    wg0 = {
      address = [ "10.192.123.1/24" ];
      listenPort = 51820;
      privateKeyFile = "/zfs/wg-privkey";

      peers = [
        {
          # work-lapton
          publicKey = "oxynuj7S/TeyRvcnBcNOMfwmlFxSLBVwGX5KggUoSic=";
          allowedIPs = [ "10.192.123.2/32" ];
        }
        {
          # mobile
          publicKey = "+my/01kg+R8Dza1Ge3jiapKXu5Eo+CFGoxrZRXhW0g0=";
          allowedIPs = [ "10.192.123.3/32" ];
        }
        {
          # ilektraphon
          publicKey = "ow8UIpVPsV0BcnZ/6d0VRWjgwvgpxYg7Du38WfQPli8=";
          allowedIPs = [ "10.192.123.5/32" ];
        }
        {
          # Ipad
          publicKey = "mzdCqfAIY4cxFoIu9L7l9fACWwyKHldOBccpPUiB7Go=";
          allowedIPs = [ "10.192.123.6/32" ];
        }
      ];
    };
  };

  services.prometheus.exporters.node.listenAddress="172.26.64.1";
  services.prometheus.exporters.smartctl = {
    enable = true;
    listenAddress="172.26.64.1";
  };
  services.prometheus.exporters.smokeping = {
    enable = true;
    listenAddress="172.26.64.1";
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


  services.rsyslogd = {
    enable = true;

    extraConfig = ''
      $AllowedSender TCP, 192.168.2.1
      $AllowedSender TCP, 192.168.2.202
      $template RemoteLogs,"/var/log/%HOSTNAME%/%PROGRAMNAME%.log"
      if $fromhost-ip startswith "192.168.2" then ?RemoteLogs
      & stop

      module(load="imtcp")
      input(type="imtcp" port="514" Address="192.168.2.3")
    '';
  };

  power.ups = {
    enable = true;

    ups."eaton" = {
      driver = "usbhid-ups";
      port = "auto";
      description = "Eaton UPS";
    };

    users.monitor = {
      passwordFile = "/etc/nixos/upspass";
      upsmon = "primary";
    };

    upsd = {
      enable = true;
      listen = [
        { address = "127.0.0.1"; }
      ];
    };

    upsmon = {
      enable = true;
      monitor.eaton = {
        user = "monitor";
        type = "master";
        powerValue = 1;
      };
    };
  };

  services.prometheus.exporters.nut = {
    enable = true;
    listenAddress = "172.26.64.1";
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
  system.stateVersion = "24.11";
}
