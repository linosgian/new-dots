{home-manager, config, pkgs, ...}:
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.lgian = { lib, ...}:{
    home.stateVersion = "24.11";
    imports = [
      ./kitty
      ./sway
      ./swaync
      ./rofi
      ./kanshi
      ./git
      (import ./waybar {
        inherit config pkgs home-manager;
        bigger-bar-screens = [ "Dell Inc. DELL S2721DGF CTPGZ83" "BNQ BenQ EL2870U W4M06094SL0" ];
        smaller-bar-screens = [ "eDP-1" ];
      })
    ];

    home.packages = with pkgs; [
      (import ../pkgs/sway-scripts { inherit pkgs; })
      fzf
      ripgrep
      evince
      tmux
    ];

    services.ssh-agent = {
      enable = true;
    };

    programs.ssh = {
      enable = true;
      matchBlocks = {
        "router" = {
          hostname = "router.lgian.com";
          identityFile = "~/.ssh/old";
          user = "root";
        };
        "mutual" = {
          hostname = "192.168.5.2";
          identityFile = "~/.ssh/olddstop";
          proxyJump = "router";
        };
        "headscale" = {
          hostname = "headscale.lgian.com";
          identityFile = "~/.ssh/old";
        };
        "connector" = {
          hostname = "connector.lgian.com";
          identityFile = "~/.ssh/old";
        };
        "strovilos" = {
          hostname = "strovilos.gr";
          port = 3000;
          identityFile = "~/.ssh/old";
          user = "ragan";
        };
        "ntoulapa" = {
          hostname = "ntoulapa.lgian.com";
          identityFile = "~/.ssh/old";
        };
      };
    };
  };
}
