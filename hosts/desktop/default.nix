{ lib, config, pkgs, ... }:
{
  imports = [
    ../../blueprints/workstation.nix
    ./hardware-configuration.nix
  ];

  boot.binfmt.emulatedSystems = [ "aarch64-linux" ];
  services.irqbalance.enable = true;
  home-manager.users.lgian.wayland.windowManager.sway.config.workspaceOutputAssign = [
    {
      output = "HDMI-A-1";
      workspace = "1";
    }
    {
      output = "HDMI-A-1";
      workspace = "2";
    }
    {
      output = "DVI-D-2";
      workspace = "3";
    }
    {
      output = "HDMI-A-1";
      workspace = "4";
    }
    {
      output = "DVI-D-2";
      workspace = "5";
    }
    {
      output = "HDMI-A-1";
      workspace = "6";
    }
    {
      output = "HDMI-A-1";
      workspace = "7";
    }
    {
      output = "HDMI-A-1";
      workspace = "8";
    }
    {
      output = "HDMI-A-1";
      workspace = "9";
    }
  ];
  home-manager.users.lgian.services.kanshi.settings = [
    {
      profile.name = "default";
      profile.outputs = [
        {
          criteria = "Dell Inc. DELL S2721DGF CTPGZ83";
          status = "enable";
          mode = "2560x1440@59.951Hz";
          position = "0,0";
          scale = 1.0;
        }
        {
          criteria = "BNQ BenQ EL2870U W4M06094SL0";
          status = "enable";
          mode = "2560x1440@59.951Hz";
          position = "2560,0";
          scale = 1.0;
        }
      ];
    }
  ];

  system.stateVersion = "24.11";
}
