{ lib, ... }:
{
  disko.devices = {
    disk = {
      # Primary SSD for NixOS
      sda = {
        type = "disk";
        device = "/dev/disk/by-id/ata-Samsung_SSD_860_EVO_250GB_S4CJNF0NC35989N";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              name = "boot";
              size = "1G";
              type = "EF00"; # EFI System Partition
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              name = "root";
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "system_vg";
              };
            };
          };
        };
      };

      nvme = {
        type = "disk";
        device = "/dev/disk/by-id/nvme-Samsung_SSD_970_EVO_Plus_500GB_S4EVNX1W493080V";
        content = {
          type = "gpt";
          partitions = {
            cache_and_zfs = {
              name = "cache_and_zfs";
              size = "100%";
              content = {
                type = "lvm_pv";
                vg = "cache_vg";
              };
            };
          };
        };
      };
    };

    lvm_vg = {
      # System volume group on first SSD
      system_vg = {
        type = "lvm_vg";
        lvs = {
          root = {
            size = "200G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
          swap = {
            size = "8G";
            content = {
              type = "swap";
            };
          };
        };
      };

      cache_vg = {
        type = "lvm_vg";
        lvs = {
          l2arc = {
            size = "25G";
          };
          ssd = {
            size = "100%FREE";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/ssd-new";
            };
          };
        };
      };
    };
  };
}
