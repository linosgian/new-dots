{home-manager, config, pkgs, ...}:
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.lgian = { lib, ...}:{
    home.stateVersion = "24.11";
    imports = [
      ./zsh
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
    ];

    services.ssh-agent = {
      enable = true;
    };
  };
}
