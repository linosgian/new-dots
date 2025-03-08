{lib, config, pkgs,...}:
{
  imports = [
    ../../blueprints/workstation.nix
    ./hardware-configuration.nix
  ];
  services.irqbalance.enable = true;

  system.stateVersion = "24.11";
}
