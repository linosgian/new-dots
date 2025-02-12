{home-manager, config, pkgs, ...}:
{
  services.kanshi = {
    enable = true;
    settings = [
      {
        profile.name = "default";
        profile.outputs = [
          {
            criteria = "AU Optronics 0x573D Unknown";
            status = "enable";
            mode = "1920x1080@60.033Hz";
            position = "0,0";
          }
        ];
      }
      {
        profile.exec = [
          ''${pkgs.sway}/bin/swaymsg workspace 3, move workspace to '"BNQ BenQ EL2870U W4M06094SL0"' ''
          ''${pkgs.sway}/bin/swaymsg workspace 5, move workspace to '"BNQ BenQ EL2870U W4M06094SL0"' ''
        ];
        profile.name = "docked";
        profile.outputs = [
          {
            criteria = "AU Optronics 0x573D Unknown";
            status = "disable";
          }
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
  };
}
