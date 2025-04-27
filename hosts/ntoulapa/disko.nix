{ lib, ... }:
{
  disko.devices = {
    disk = {
      # Primary SSD for NixOS
      sda = {
        type = "disk";
        device = "/dev/sda";
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
      
      # Secondary SSD for caching and ZFS acceleration
      sdb = {
        type = "disk";
        device = "/dev/sdb";
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
      
      # Cache volume group on second SSD
      cache_vg = {
        type = "lvm_vg";
        lvs = {
          transcode_cache_cine = {
            size = "50G";
            # handle this manually through nixvirt
          };
          transcode_cache = {
            size = "100G";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/ssd";
            };
          };
          l2arc = {
            size = "70G";
          };
        };
      };
    };
  };
}
