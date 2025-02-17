{ config , lib , pkgs , ...  }:
{

  imports = [
    ./common.nix
    ../modules/vim/server.nix
  ];

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

