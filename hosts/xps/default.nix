{config, pkgs,...}:
{
  imports = [
    ../../blueprints/workstation.nix
    ../../blueprints/laptop.nix
    ./hardware-configuration.nix
  ];
  services.irqbalance.enable = true;
}
