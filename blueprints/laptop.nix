{ config , lib , pkgs , ...  }:
{
  environment.systemPackages = with pkgs; [
    brightnessctl
    libinput
    libinput-gestures
  ];
  networking.networkmanager.enable = true;
  networking.networkmanager.wifi.macAddress = "stable";
  networking.firewall.enable = true;
  networking.networkmanager.wifi.backend = "iwd";
  networking.wireless.iwd = {
    enable = true;
    settings = {
      General.AddressRandomization = "stable";
      General.AddressRandomizationRange = "full";
    };
  };
  hardware.bluetooth.enable = true;
  hardware.bluetooth.settings = {
    General = {
      FastConnectable = true;
      JustWorksRepairing = "always";
      Privacy = "device";
      MultiProfile = "multiple";
      Experimental = true;
      KernelExperimental = true;
    };
    Policy = {
      AutoEnable = true;
      ResumeDelay = 2;
    };
  };

  virtualisation.libvirtd.enable = true;
  services.hardware.bolt.enable = true;

  ## usb devices can interfere with sleep without the below
  systemd.services.disable-usb-wakeup = rec {
    description = "Disable USB wakeup";
    enable = true;
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    script = ''
      echo XHC > /proc/acpi/wakeup
    '';
    postStop = ''
      echo XHC > /proc/acpi/wakeup
    '';
    wantedBy = [ "multi-user.target" ];
  };

}
