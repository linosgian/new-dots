{ config , lib , pkgs , ...  }:
{
  imports = [
    ./vim.nix
    ./..
    ./boot.nix
  ];
  environment.systemPackages = with pkgs; [
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
    eog # image viewer
    nmap
    gnome-calculator
    chromium
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
    direnv
    dive
    virt-manager
    qemu
    virt-viewer
  ];
  services.udisks2.enable = true;
  services.avahi.enable = true;

  security.rtkit.enable = true;
  programs.ssh = {
    startAgent = true;
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
                   "api.alsa.period-size"   = 1024;
                   "api.alsa.headroom"      = 8192;
                };
              };
            }
          ];
        };
      };
    };
  };
}
