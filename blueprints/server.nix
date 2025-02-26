{ config , lib , pkgs , ...  }:
{

  imports = [
    ./common.nix
    ../modules/vim/server.nix
  ];
  services.prometheus.exporters.node = {
    enable = true;
    openFirewall = true; # Opens port 9100 in the firewall
    extraFlags = [
      "--collector.filesystem.ignored-mount-points" "^/(sys|proc|dev|run)($|/)"
      "--collector.filesystem.ignored-fs-types" "^(tmpfs|devtmpfs|overlay|squashfs|bpf)$"
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

