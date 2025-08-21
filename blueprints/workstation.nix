{ inputs, config, lib, pkgs, ... }:
{
  imports = [
    ../modules/vim
    ./common.nix
    ../modules/boot.nix
    ../modules/home.nix
    ../modules/wayland.nix
  ];
  environment.systemPackages = with pkgs; [
    geeqie
    gnome-keyring
    linuxPackages.cpupower
    wl-clipboard
    wlr-randr
    bluez-tools
    bluez
    blueman
    pulseaudio
    networkmanagerapplet
    pavucontrol
    gnome-calculator
    kitty
    gnome-disk-utility
    evince
    spotify
    playerctl
    docker-compose
    nix-index
    nix-direnv
    nix-diff
    nix-tree
    dive
    virt-manager
    qemu
    virt-viewer
    ansible
    entr
    whitesur-cursors
    terraform
    age
    sops
    obsidian
  ];
  services.udisks2.enable = true;
  services.avahi = {
    enable = true;
    nssmdns4 = true;
  };
  virtualisation.docker.enable = true;
  security.rtkit.enable = true;
  programs.ssh = {
    enableAskPassword = true;
  };
  services.printing = {
    enable = true;
  };
  programs.firefox = {
    enable = true;
  };
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    wireplumber = {
      enable = true;
      extraConfig = {
        "99-disable-suspend" = {
          "monitor.alsa.rules" = [
            {
              matches = [
                {
                  "node.name" = "~alsa_input.*";
                }
              ];
              actions = {
                update-props = {
                  "session.suspend-timeout-seconds" = 0;
                  "api.alsa.period-size" = 1024;
                  "api.alsa.headroom" = 8192;
                };
              };
            }
          ];
        };
      };
    };
  };
}
