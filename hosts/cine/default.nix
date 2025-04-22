{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [
    ../../blueprints/server.nix
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  services.qemuGuest.enable = true;
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };

  boot.loader.grub.device = lib.mkDefault "/dev/vda";
  boot.kernelParams = [
    "console=ttyS0,115200"
    "console=tty1" # enables libvirt console
  ];
  boot.growPartition = true;

  boot.kernelModules = [ "virtiofs" ];

  fileSystems."/media" = {
    device = "media";
    fsType = "virtiofs";
    options = [ "defaults" "nofail" ];
  };

  system.build.qcow2 = import "${modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;
    diskSize = 10240;
    format = "qcow2";
    partitionTableType = "hybrid";
  };

  networking.nameservers = ["1.1.1.1"];

  networking.hostName = "cine";
  networking.useDHCP = lib.mkDefault true;
  networking.firewall.interfaces."enp0s3".allowedTCPPorts = [ 9000 9999 ];
  networking.firewall.interfaces."tailscale0".allowedTCPPorts = [ 9000 9999 ];

  services.tailscale.enable = true;

  environment.systemPackages = with pkgs; [
    minio-client
  ];

  system.stateVersion = "24.11";
}
