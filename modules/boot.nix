{ config, lib, pkgs, ... }:
{
  boot = {
    initrd.compressor = "zstd";
    initrd.systemd = {
      enable = true;
      network.enable = true;
      emergencyAccess = true;
    };
    loader.systemd-boot = {
      enable = true;
      consoleMode = lib.mkDefault "max";
      netbootxyz.enable = true;
      memtest86.enable = true;
      configurationLimit = 8;
    };
    consoleLogLevel = 0;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "udev.log_level=0"
      "udev.log_priority=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "boot.shell_on_fail"
    ];
    plymouth = {
      enable = true;
      theme = "abstract_ring";
      themePackages = [
        (pkgs.adi1090x-plymouth-themes.override {
          selected_themes = [
            "abstract_ring"
          ];
        })
      ];
    };
    loader.timeout = 1;
    loader.efi.canTouchEfiVariables = true;
    tmp.useTmpfs = true;
  };
}
