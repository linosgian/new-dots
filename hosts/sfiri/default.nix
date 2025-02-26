{
  config,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    ../../blueprints/server.nix
    ./cups.nix
    ./klipper.nix
  ];
  networking.hostName = "sfiri";

  networking.networkmanager.enable = false;
  networking.interfaces."wlan0".useDHCP = true;
  networking.wireless = {
    enable = true;
    interfaces = [ "wlan0" ];
    networks."TENTA_5G".psk = "linakoss123";
    extraConfig = "ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=wheel";
  };
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];
  system.stateVersion = "24.11"; # DO NOT CHANGE ME
}
