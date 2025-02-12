{home-manager, config, pkgs, ...}:
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.lgian = { lib, ...}:{
    home.stateVersion = "24.11";
    imports = [
      ./shikane.nix
      ./zsh
      ./shikane
      ./kitty
      ./sway
      ./swaync
      ./rofi
      ./git
      (import ./waybar {
        inherit config pkgs home-manager;
        bigger-bar-screens = [ "DP-3" "DP-4" ];
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
