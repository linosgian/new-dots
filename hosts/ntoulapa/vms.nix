{ nixvirt, ...  }:
{
    virtualisation.libvirt.connections."qemu:///system" = {
      domains = [
        {
          definition = nixvirt.lib.domain.writeXML (
            {
              type = "kvm";
              name = "mutual";
              uuid = "ee43005c-2e7b-4af2-bfae-8c52eeb22672";
              memory = {
                count = 4;
                unit = "GiB";
              };
              vcpu =
                {
                  placement = "static";
                  count = 2;
                };
              os =
                {
                  type = "hvm";
                  arch = "x86_64";
                  machine = "pc-i440fx-2.9";
                  boot = [{ dev = "cdrom"; } { dev = "hd"; }];
                  bootmenu = { enable = true; };
                };
              clock =
                {
                  offset = "localtime";
                  timer =
                    [
                      { name = "rtc"; tickpolicy = "catchup"; }
                      { name = "pit"; tickpolicy = "delay"; }
                      { name = "hpet"; present = false; }
                    ];
                };
              on_poweroff = "destroy";
              on_reboot = "destroy";
              on_crash = "destroy";

              devices =
                let
                  pci_address = bus: slot: function:
                    {
                      type = "pci";
                      domain = 0;
                      bus = bus;
                      slot = slot;
                      inherit function;
                    };
                  drive_address = unit:
                    {
                      type = "drive";
                      controller = 0;
                      bus = 0;
                      target = 0;
                      inherit unit;
                    };
                in
                {
                  emulator = "/run/current-system/sw/bin/qemu-system-x86_64";
                  disk =
                    [
                      {
                        type = "file";
                        device = "disk";
                        driver =
                          {
                            name = "qemu";
                            type = "qcow2";
                            cache = "writeback";
                          };
                        source =
                          {
                            file = /home/lgian/nixos.qcow2;
                          };
                        target =
                          {
                            bus = "sata";
                            dev = "sda";
                          };
                        address = drive_address 0;
                      }
                    ];
                  interface =
                    {
                      type = "bridge";
                      mac = { address = "52:54:00:10:c4:28"; };
                      source = { bridge = "br-vlan106"; };
                      model = { type = "virtio"; };
                      address = pci_address 2 1 0;
                    };
                  serial =
                    {
                      type = "pty";
                      target =
                        {
                          type = "isa-serial";
                          port = 0;
                          model = { name = "isa-serial"; };
                        };
                    };
                  console =
                    {
                      type = "pty";
                      target = { type = "serial"; port = 0; };
                    };
                };
            }
          );
          active = true;
        }
      ];
    };
  }
