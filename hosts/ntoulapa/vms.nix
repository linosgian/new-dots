{ nixvirt, ... }:
let
  # Helper function to create a virtiofs mount configuration
  createVirtiofsMountpoint = { 
    hostPath, 
    targetTag, 
    slot,
    accessmode ? "passthrough" 
  }: {
    type = "mount";
    driver = {
      type = "virtiofs";
    };
    source = {
      dir = hostPath;
    };
    target = {
      dir = targetTag;
    };
    address = {
      type = "pci";
      domain = 0;
      bus = 2;
      slot = slot;
      function = 0;
    };
    accessmode = accessmode;
  };
  createDomain = { 
    name, 
    uuid, 
    diskPath, 
    macAddress,
    memoryGiB ? 4,
    vcpuCount ? 2,
    virtiofsMounts ? []
  }: {
    definition = nixvirt.lib.domain.writeXML ({
      type = "kvm";
      inherit name uuid;
      memoryBacking = {
        source = { type = "memfd"; };
        access = { mode = "shared"; };
      };
      memory = {
        count = memoryGiB;
        unit = "GiB";
      };
      vcpu = {
        placement = "static";
        count = vcpuCount;
      };
      os = {
        type = "hvm";
        arch = "x86_64";
        machine = "pc-i440fx-2.9";
        boot = [{ dev = "cdrom"; } { dev = "hd"; }];
        bootmenu = { enable = true; };
      };
      clock = {
        offset = "localtime";
        timer = [
          { name = "rtc"; tickpolicy = "catchup"; }
          { name = "pit"; tickpolicy = "delay"; }
          { name = "hpet"; present = false; }
        ];
      };
      on_poweroff = "destroy";
      on_reboot = "restart";
      on_crash = "restart";
      devices = let
        pci_address = bus: slot: function: {
          type = "pci";
          domain = 0;
          bus = bus;
          slot = slot;
          inherit function;
        };
        drive_address = unit: {
          type = "drive";
          controller = 0;
          bus = 0;
          target = 0;
          inherit unit;
        };
      in {
        emulator = "/run/current-system/sw/bin/qemu-system-x86_64";
        disk = [
          {
            type = "file";
            device = "disk";
            driver = {
              name = "qemu";
              type = "qcow2";
              cache = "writeback";
            };
            source = {
              file = diskPath;
            };
            target = {
              bus = "sata";
              dev = "sda";
            };
            address = drive_address 0;
          }
        ];
        interface = {
          type = "bridge";
          mac = { address = macAddress; };
          source = { bridge = "br-vlan106"; };
          model = { type = "virtio"; };
          address = pci_address 2 1 0;
        };
        serial = {
          type = "pty";
          target = {
            type = "isa-serial";
            port = 0;
            model = { name = "isa-serial"; };
          };
        };
        console = {
          type = "pty";
          target = { type = "serial"; port = 0; };
        };
        filesystem = virtiofsMounts;
        memballoon = {
          model = "virtio";
          address = pci_address 2 4 0;
        };
      };
    });
    active = true;
  };

  # Define your domains here
  domains = [
    # First domain
    (createDomain {
      name = "mutual";
      uuid = "ee43005c-2e7b-4af2-bfae-8c52eeb22672";
      diskPath = /home/lgian/nixos.qcow2;
      macAddress = "52:54:00:10:c4:28";
    })

    # Second domain
    (createDomain {
      name = "cinelgian";
      uuid = "ff43005c-2e7b-4af2-bfae-8c52eeb22673";
      diskPath = /home/lgian/cine.qcow2;
      macAddress = "52:54:00:10:c4:29";
      virtiofsMounts = [
        (createVirtiofsMountpoint {
          hostPath = "/zfs/torrents/complete";
          targetTag = "media";
          slot = 5;
        })
      ];
    })
  ];
in
{
  virtualisation.libvirt.connections."qemu:///system" = {
    domains = domains;
  };
}
