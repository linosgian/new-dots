{ config , lib , pkgs , ...  }:
{

  imports = [
    ./common.nix
    ../modules/vim/server.nix
  ];

  environment.systemPackages = with pkgs; [
    rsyslog
    ethtool
  ];
  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = true; # Opens port 9100 in the firewall
    extraFlags = [
      "--collector.filesystem.ignored-fs-types" "^(tmpfs|devtmpfs|overlay|squashfs|bpf)$"
      "--collector.systemd"
      "--no-collector.pressure"
      "--collector.filesystem.ignored-mount-points" "^/(sys|proc|dev|host|etc|run|boot|rootfs/var/lib/docker/containers|rootfs/var/lib/docker/overlay2|rootfs/run/docker/netns|rootfs/var/lib/docker/aufs|rootfs/var/lib/docker/devicemapper|rootfs/var/nomad/.+|var/nomad/.+)($$|/)"
      "--collector.netclass.ignored-devices" "^(veth.+|docker[0-9])$"
      "--collector.netdev.device-exclude" "^(veth.+|docker[0-9])$"
    ];
  };
  services = {
    openssh = {
      enable = true;
      ports = [ 22 ];
      openFirewall = true;
      listenAddresses = [{
        addr = "0.0.0.0";
      }];
      settings = {
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PermitRootLogin = lib.mkDefault "no";
        PrintMotd = false;
        ClientAliveInterval = 60;
        ClientAliveCountMax = 10;
        AllowUsers = ["lgian"];
      };
    };
    locate = {
      enable = true;
    };
  };
}

