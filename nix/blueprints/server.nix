{ config , lib , pkgs , ...  }:
{

  imports = [
    ./common.nix
  ];
  environment.systemPackages = with pkgs; [
  ];
}

