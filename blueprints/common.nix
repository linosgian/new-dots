{ config , lib , pkgs , ...  }:
{

  imports = [
    ../modules/user.nix
    ../modules/zsh
  ];
  environment.systemPackages = with pkgs; [
    nixVersions.stable
    curl
    git
    wireguard-tools
    fping
    dig
    iperf3
    powertop
    htop
    tree
    lm_sensors
    tcpdump
    cryptsetup
    jq
    jnv
    yj
    file
    ncdu
    usbutils
    fwupd
    dmidecode
    pciutils
    lshw
    ripgrep
    bashInteractive
    nixpkgs-fmt
    nixfmt-rfc-style
    nix-output-monitor
    nixd
    screen
    fzf
    kitty.terminfo
    direnv
    exiftool
  ];
  nixpkgs.config.allowUnfree = true;
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Athens";

  services.fwupd.enable = true;
  services.ntp.enable = true;
  nix.settings = {
    trusted-users = [ "root" "lgian" "@wheel" ];
    experimental-features = [ "nix-command" "flakes" ];
  };
}
