{ pkgs, ... }:
{
  services.printing = {
    enable = true;
    drivers = [
      pkgs.gutenprint
    ];
    allowFrom = [ "all" ];
    browsing = true;
    defaultShared = true;
    listenAddresses = [ "*:631" ];
    openFirewall = true;
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
    publish = {
      enable = true;
      userServices = true;
    };
  };

  hardware.printers = {
    ensurePrinters = [
      {
        name = "xrepi";
        location = "Home";
        deviceUri = "lpd://192.168.3.127/queue";
        model = "gutenprint.5.3://bjc-MULTIPASS-MP495/expert";
        ppdOptions = {
          PageSize = "A4";
        };
      }
    ];
    ensureDefaultPrinter = "xrepi";
  };
}
