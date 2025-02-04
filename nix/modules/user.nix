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

    home = "/home/lgian";
  };
}
