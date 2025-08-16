{ lib, config, pkgs, unstablePkgs, ... }:
{
  imports = [
    ../../blueprints/workstation.nix
    ../../blueprints/laptop.nix
    ./hardware-configuration.nix
  ];

  hardware.sane = {
    enable = true;
    openFirewall = true;
  };
  # Override pixma.conf in sane.configDir
  environment.etc."sane-config" = lib.mkForce {
    source = pkgs.runCommand "custom-sane-config" {} ''
      mkdir -p $out
      cp -r ${config.hardware.sane.configDir}/* $out/
      rm $out/pixma.conf
      cat > $out/pixma.conf << EOF
      # Hardcoded Canon scanner on remote network
      networking=true
      bjnp://192.168.3.127:8612
      EOF
    '';
  };
  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  networking.hostName = "x1";
  services.thinkfan = {
    enable = true;
    #sensor = "/sys/devices/virtual/thermal/thermal_zone0/temp";
    levels = [
      [ 0 0 55 ]
      [ "level auto" 53 87 ]
      [ "level full-speed" 85 95 ]
      [ "level disengaged" 93 32767 ]
    ];

  };
  services.irqbalance.enable = true;
  environment.systemPackages = with pkgs; [
    aws-vault
    awscli2
    python3
    k9s
    kubectl
    kubectx
    slack
    simple-scan
    darktable
    unstablePkgs.cura-appimage
  ];


  home-manager.users.lgian.programs.ssh = {
    enable = true;
    matchBlocks = {
      "gitlab-mgr.cf" = {
        hostname = "gitlab-runner-manager.util.eu-central-1a.ec2.cfl";
      };
      "gitlab.cf" = {
        hostname = "gitlab.cloud.contextflow.com";
        port = 2222;
      };
      "*.cf" = {
        identityFile = "/home/lgian/.ssh/work";
        identitiesOnly = true;
      };
      "*.cfl" = {
        identityFile = "/home/lgian/.ssh/work";
        identitiesOnly = true;
      };
      "*.contextflow.com" = {
        identityFile = "/home/lgian/.ssh/work";
        identitiesOnly = true;
      };
      "*.dcm.gg" = {
        identityFile = "/home/lgian/.ssh/work";
        identitiesOnly = true;
      };
    };
  };

  home-manager.users.lgian.services.kanshi.settings = [
    {
      profile.name = "default";
      profile.outputs = [
        {
          criteria = "AU Optronics 0x573D Unknown";
          status = "enable";
          mode = "1920x1080@60.033Hz";
          position = "0,0";
        }
      ];
    }
    {
      profile.exec = [
        ''${pkgs.sway}/bin/swaymsg workspace 3, move workspace to '"BNQ BenQ EL2870U W4M06094SL0"' ''
        ''${pkgs.sway}/bin/swaymsg workspace 5, move workspace to '"BNQ BenQ EL2870U W4M06094SL0"' ''
      ];
      profile.name = "docked";
      profile.outputs = [
        {
          criteria = "AU Optronics 0x573D Unknown";
          status = "disable";
        }
        {
          criteria = "Dell Inc. DELL S2721DGF CTPGZ83";
          status = "enable";
          mode = "2560x1440@59.951Hz";
          position = "0,0";
          scale = 1.0;
        }
        {
          criteria = "BNQ BenQ EL2870U W4M06094SL0";
          status = "enable";
          mode = "2560x1440@59.951Hz";
          position = "2560,0";
          scale = 1.0;
        }
      ];
    }
  ];

  networking.wg-quick.interfaces = {
    wg0 = {
      autostart = true;
      address = [ "192.168.10.28/32" ];
      listenPort = 51822;
      privateKeyFile = "/etc/nixos/cf-privkey";

      peers = [
        {
          publicKey = "bqOVQlwuEu3mXx/k0rRoMF4csjnG54uFz8JuEf63xQA=";

          allowedIPs = [ "192.168.160.0/22" "192.168.2.15/32" "192.168.163.231/24"  "192.168.10.3/32" "192.168.128.0/24" "192.168.10.0/24" "192.168.129.206/24" "192.168.129.206/24" "192.168.131.0/24" "192.168.130.214/24" "10.100.0.0/16" "10.250.0.0/16" "10.200.0.0/16" "10.1.0.0/16" ];
          endpoint = "cf-wg-eu-90544ccb5a9cb155.elb.eu-central-1.amazonaws.com:55442";
        }
      ];
    };

    wg1 = {
      autostart = false;
      address = [ "10.192.123.2/32" ];
      listenPort = 51821;
      privateKeyFile = "/etc/nixos/home-privkey";

      peers = [
        {
          publicKey = "mr231PdFN46Os/OH+lXpTbfSN61pKdbiW1hqYY9n9Hk=";

          allowedIPs = [ "10.192.123.0/24" ];
          endpoint = "hm.lgian.com:51820";
        }
      ];
    };
  };

  services.dnsmasq = {
    enable = true;
    settings = {
      listen-address = "127.0.0.1";
      bind-interfaces = true;
    };
    resolveLocalQueries = true;
    settings.server = [
      "/.cfl/10.100.0.2"
      "/.cf/10.100.0.2"
      "/*.cloud.contextflow.com/10.100.0.2"
      "/*.dcm.gg/10.100.0.2"
      "/937DE1F752050623115CE038A346EA0E.gr7.eu-central-1.eks.amazonaws.com/10.100.0.2"
    ];
  };
  system.stateVersion = "24.11";
}
