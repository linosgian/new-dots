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
      ../../modules/nomad.nix
      ../../modules/consul.nix
      (modulesPath + "/profiles/qemu-guest.nix")
    ];
  virtualisation.diskSize = 50 * 1024 ; # in MB
  virtualisation.memorySize = 24000;
  virtualisation.cores = 4;
  services.qemuGuest.enable = true;
  boot.initrd.availableKernelModules = [ "ata_piix" "uhci_hcd" "virtio_pci" "floppy" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # networking.vlans.vlan105 = {
  #   id = 105;
  #   interface = "eth0";
  # };

  # networking.bridges = {
  #   "br-vlan105" = {
  #     interfaces = [ "eth0.105" ];
  #   };
  # };

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
  networking.hostName = "ntoulapa";
  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    settings.server= [
      "/.consul/127.0.0.1#8600"
      "192.168.2.1"
    ];
  };

  environment.systemPackages = with pkgs; [
    restic
  ];
  services.restic.backups.ntoulapa = {
    repository = "s3:http://snf-77423.ok-kno.grnetcloud.net:9000/restic-backups";
    initialize = true;
    passwordFile = "/etc/nixos/restic-password";  # File containing Restic repository password
    environmentFile = "/etc/nixos/minio-credentials"; # Exposes AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY
    paths = [ "/home/lgian/boo"]; # Folders to back up
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
    pruneOpts = [
      "--keep-last 7"
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
      "--prune"
    ];
  };
  security.acme.defaults.email = "linosgian00@gmail.com";
  security.acme.acceptTerms = true;
  security.acme.defaults.server = "https://acme-v02.api.letsencrypt.org/directory";
  security.acme.certs."foo.lgian.com" = {
    domain = "*.foo.lgian.com";
    dnsProvider = "digitalocean";
    dnsPropagationCheck = true;
    environmentFile = "${pkgs.writeText "do-creds" ''
      DO_AUTH_TOKEN=dop_v1_5be6c5fd53f9195685d8433950d70845b91007c998453798fd99ba7cc038cd97
      DO_PROPAGATION_TIMEOUT=600
      DO_POLLING_INTERVAL=60
    ''}";
  };
  time.timeZone = "Europe/Athens";
  networking.firewall.allowedTCPPorts = [ 22 4646 4647 4648 8500 8600 8300 8301 8302 ];
  networking.firewall.allowedUDPPorts = [ 4648 8600 8301 8302 53];

  services.rsyslogd = {
    enable = true;

    extraConfig = ''
      $AllowedSender TCP, 192.168.2.1
      $AllowedSender TCP, 192.168.2.202
      $template RemoteLogs,"/var/log/%HOSTNAME%/%PROGRAMNAME%.log"
      if $fromhost-ip startswith "192.168.2" then ?RemoteLogs
      & stop

      module(load="imtcp")
      input(type="imtcp" port="514" Address="10.0.2.15")
    '';
  };

  virtualisation.forwardPorts = [
    { from = "host"; host.port = 24646; guest.port = 4646; } # Nomad API
    { from = "host"; host.port = 28500; guest.port = 8500; } # Consul API
    { from = "host"; host.port = 28600; guest.port = 8600; } # Consul DNS
    { from = "host"; host.port = 2222; guest.port = 22; } # Consul DNS
  ];
  system.stateVersion = "24.11"; # DO NOT CHANGE ME
}
