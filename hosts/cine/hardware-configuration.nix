{ config
, lib
, pkgs
, modulesPath
, ...
}:
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  services.qemuGuest.enable = true;
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };
  fileSystems."/media" = {
    device = "media";
    fsType = "virtiofs";
    options = [ "defaults" "nofail" ];
  };
  fileSystems."/ssd" = {
    device = "cache";
    fsType = "virtiofs";
    options = [ "defaults" "nofail" ];
  };
  fileSystems."/var/lib/jellyfin" = {
    device = "jellyfin";
    fsType = "virtiofs";
    options = [ "defaults" "nofail" ];
  };

  boot.loader.grub.device = lib.mkDefault "/dev/vda";
  boot.kernelParams = [
    "console=ttyS0,115200"
    "console=tty1" # enables libvirt console
  ];
  boot.growPartition = true;

  boot.kernelModules = [ "virtiofs" ];

  system.build.qcow2 = import "${modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;
    diskSize = 10240;
    format = "qcow2";
    partitionTableType = "hybrid";
  };
}
