{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{

  imports =
    [
      ../../blueprints/server.nix
      (modulesPath + "/profiles/qemu-guest.nix")
    ];
  virtualisation.diskSize = 10 * 1024 ; # in MB
  virtualisation.memorySize = 4048;
  services.qemuGuest.enable = true;
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "floppy" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/2723e2d9-c8d1-4fcd-b587-93f82b36b826";
      fsType = "ext4";
    };

  fileSystems."/nix/.ro-store" =
    { device = "nix-store";
      fsType = "9p";
    };

  fileSystems."/nix/.rw-store" =
    { device = "tmpfs";
      fsType = "tmpfs";
    };

  fileSystems."/tmp/shared" =
    { device = "shared";
      fsType = "9p";
    };

  fileSystems."/tmp/xchg" =
    { device = "xchg";
      fsType = "9p";
    };

  fileSystems."/nix/store" =
    { device = "overlay";
      fsType = "overlay";
    };

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  boot.kernelParams = [
    "console=ttyS0,115200"
    "console=tty1" # enables libvirt console
  ];
  boot.growPartition = true;
  boot.loader.grub.device = lib.mkForce "/dev/disk/by-uuid/2723e2d9-c8d1-4fcd-b587-93f82b36b826";
  networking.hostName = "nomads";
  time.timeZone = "Europe/Athens";
  networking.firewall.allowedTCPPorts = [ 22 4646 4647 4648 8500 8600 8300 8301 8302 ];
  networking.firewall.allowedUDPPorts = [ 4648 8600 8301 8302 ];

  virtualisation.forwardPorts = [
    { from = "host"; host.port = 24646; guest.port = 4646; } # Nomad API
    { from = "host"; host.port = 28500; guest.port = 8500; } # Consul API
    { from = "host"; host.port = 28600; guest.port = 8600; } # Consul DNS
    { from = "host"; host.port = 2222; guest.port = 22; } # Consul DNS
  ];

  nix.settings.trusted-users = [
    "lgian"
    "root"
  ];
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  system.stateVersion = "24.05"; # DO NOT CHANGE ME
}
