{
  home-manager,
  config,
  pkgs,
  ...
}:
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.lgian =
    { lib, ... }:
    {
      home.stateVersion = "25.05";
      imports = [
        ./kitty
        ./sway
        ./swaync
        ./rofi
        ./kanshi
        ./git
        (import ./waybar {
          inherit config pkgs home-manager;
          bigger-bar-screens = [
            "Dell Inc. DELL S2721DGF CTPGZ83"
            "BNQ BenQ EL2870U W4M06094SL0"
          ];
          smaller-bar-screens = [
            "eDP-1"
            "Lenovo Group Limited LEN T2324pA V1H70807"
            "Hewlett Packard HP 2311gt 3CQ208NPY6"
          ];
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
          "blog" = {
            hostname = "snf-24475.ok-kno.grnetcloud.net";
          };
          "router" = {
            hostname = "router.lgian.com";
            user = "root";
          };
          "mutual" = {
            hostname = "192.168.5.2";
          };
          "cine" = {
            hostname = "192.168.5.3";
          };
          "headscale" = {
            hostname = "headscale.lgian.com";
          };
          "okeanos" = {
            hostname = "snf-76883.ok-kno.grnetcloud.net";
          };
          "ap" = {
            hostname = "ap.lgian.com";
            user = "root";
          };
          "strovilos" = {
            hostname = "strovilos.gr";
            port = 3000;
            user = "ragan";
          };
          "ntoulapa" = {
            hostname = "ntoulapa.lgian.com";
          };
        };
      };
    };
}
