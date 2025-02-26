{ config, pkgs, ...  }:
{
  security.sudo.wheelNeedsPassword = false;
  security.sudo.extraConfig = ''
    Defaults   env_keep += "HOME"
  '';
  users.users.lgian = {
    shell = pkgs.zsh;
    isNormalUser = true;
    initialPassword = "linos123";
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
      # work laptop
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILyy2ZIfzv+f9rGow37ljp9i78pJrSQ9zrDkz6QNgYWC lgian@nixos"
      # personal laptop
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIhO20Ny7vDijIuG9JmZJoYnVQpuv4TamJVY+J242KBr"
      # desktop
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILl3vqAFsr3e3ngwQke35m4SB1tkEjirafJHqvPRsKJ2"
    ];
    home = "/home/lgian";
  };
}
