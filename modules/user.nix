{ config, pkgs, ...  }:
{
  security.sudo.wheelNeedsPassword = false;
  security.sudo.extraConfig = ''
    Defaults   env_keep += "HOME"
  '';
  users.users.lgian = {
    shell = pkgs.zsh;
    isNormalUser = true;
    extraGroups = [
      "dialup"
      "docker"
      "input"
      "networkmanager"
      "plugdev"
      "qemu-libvirtd"
      "libvirtd"
      "scanner"
      "tty"
      "video"
      "wheel"
      "wireshark"
    ];

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILyy2ZIfzv+f9rGow37ljp9i78pJrSQ9zrDkz6QNgYWC lgian@nixos"
    ];
    home = "/home/lgian";
  };
}
