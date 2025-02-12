{home-manager, config, pkgs, ...}:
{
  services.shikane = {
    enable = true;
    profiles = [
      {
        name = "Default";
        output = [{
          search = ["m=0x573D" "s=" "v=AU Optronics"];
          enable = true;
          mode = "1920x1080@60.033Hz";
          position = "0,0";
        }];
      }
      {
        name = "docked";
        output = [
          {
            enable = false;
            search = ["m=0x573D" "s=" "v=AU Optronics"];
          }
          {
            enable = true;
            search = ["m=DELL S2721DGF" "s=CTPGZ83" "v=Dell Inc."];
            mode = "2560x1440@59.951Hz";
            position = "0,0";
            scale = 1.0;
            transform = "normal";
            adaptive_sync = false;
          }
          {
            enable = true;
            search = ["m=BenQ EL2870U" "s=W4M06094SL0" "v=BNQ"];
            mode = "2560x1440@59.951Hz";
            position = "2560,0";
            scale = 1.0;
            transform = "normal";
            adaptive_sync = false;
          }
        ];
      }
    ];
  };
}
