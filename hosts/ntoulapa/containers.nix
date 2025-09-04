{ config, pkgs, ... }:
{
  boot.enableContainers = true;
  containers.cine = {
    autoStart = true;
    privateNetwork = true;

    extraVeths.eth1 = {
      hostBridge = "br-vlan106";
    };
    

    # GPU access (the security reduction we discussed)
    bindMounts = {
      "jellyfin" = {
        mountPoint = "/var/lib/jellyfin";
        hostPath = "/zfs/jellyfin-cine";
        isReadOnly = false;
      };
      "media" = {
        mountPoint = "/media";
        hostPath = "/zfs/torrents/complete";
        isReadOnly = true;
      };
      "/dev/dri" = {
        hostPath = "/dev/dri";
        isReadOnly = false;
      };
    };

    allowedDevices = [
      {
        modifier = "rw";
        node = "/dev/dri/card0";
      }
      {
        modifier = "rw";
        node = "/dev/dri/renderD128";
      }
    ];
    config = { config, pkgs, ... }: {
      imports = [ ../cine/default.nix ];
    };
  };
}
