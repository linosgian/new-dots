{ pkgs }:
let
  yamlFormat = pkgs.formats.yaml { };
in
[
  (builtins.readFile (
    yamlFormat.generate "rules.yml" {
      groups = [
        {
          name = "unbound_alerts";
          rules = [
            {
              alert = "UnboundHighServfailRatio";
              expr = ''
                (
                  sum by (instance) (increase(unbound_answer_rcodes_total{rcode="SERVFAIL"}[1m]))
                  /
                  sum by (instance) (increase(unbound_answer_rcodes_total[1m]))
                ) > 0.2
                and
                (sum by (instance) (increase(unbound_answer_rcodes_total[1m])) > 10)
              '';
              for = "2m";
              labels.severity = "warning";
              annotations = {
                summary = "Unbound SERVFAIL ratio too high";
                description = ''
                  In the last 2 minutes, {{ $value | humanizePercentage }} of Unbound responses were SERVFAIL.
                  This may indicate upstream DNS issues or resolver misconfiguration.
                '';
              };
            }
          ];
        }
        {
          name = "nut_alerts";
          rules = [
            {
              alert = "UPSOnBattery";
              expr = ''network_ups_tools_ups_status{flag="OB"} == 1'';
              for = "1m";
              labels.severity = "warning";
              annotations = {
                summary = "UPS on battery power";
                description = "UPS '{{ $labels.model }}' is running on battery for over 1 minute.";
              };
            }
            {
              alert = "UPSLowBattery";
              expr = "network_ups_tools_battery_charge < 30";
              for = "5m";
              labels.severity = "critical";
              annotations = {
                summary = "UPS low battery";
                description = "UPS '{{ $labels.model }}' battery level is at {{ $value }}%.";
              };
            }
            {
              alert = "UPSCriticalBattery";
              expr = "network_ups_tools_battery_charge < 10";
              for = "2m";
              labels.severity = "critical";
              annotations = {
                summary = "UPS battery critically low";
                description = "UPS '{{ $labels.model }}' battery level is at {{ $value }}% and may shut down soon.";
              };
            }
            {
              alert = "UPSBatteryRuntimeCritical";
              expr = "network_ups_tools_battery_runtime < 300";
              for = "2m";
              labels.severity = "critical";
              annotations = {
                summary = "UPS battery runtime critical";
                description = "UPS '{{ $labels.model }}' has less than 5 minutes of battery remaining.";
              };
            }
            {
              alert = "UPSNoCommunication";
              expr = "absent(network_ups_tools_ups_status)";
              for = "5m";
              labels.severity = "critical";
              annotations = {
                summary = "UPS communication lost";
                description = "Prometheus has not received any UPS metrics for 5 minutes.";
              };
            }
            {
              alert = "UPSOverload";
              expr = ''network_ups_tools_ups_status{flag="OVER"} == 1'';
              for = "30s";
              labels.severity = "critical";
              annotations = {
                summary = "UPS overload";
                description = "UPS '{{ $labels.model }}' is overloaded.";
              };
            }
            {
              alert = "UPSBatteryReplacement";
              expr = ''network_ups_tools_ups_status{flag="RB"} == 1'';
              for = "1m";
              labels.severity = "warning";
              annotations = {
                summary = "UPS battery needs replacement";
                description = "UPS '{{ $labels.model }}' requires a battery replacement.";
              };
            }
            {
              alert = "UPSLowBatteryWarning";
              expr = ''network_ups_tools_ups_status{flag="LB"} == 1'';
              for = "1m";
              labels.severity = "critical";
              annotations = {
                summary = "UPS low battery warning";
                description = "UPS '{{ $labels.model }}' battery is critically low.";
              };
            }
            {
              alert = "UPSBypassActive";
              expr = ''network_ups_tools_ups_status{flag="BYPASS"} == 1'';
              for = "1m";
              labels.severity = "warning";
              annotations = {
                summary = "UPS in bypass mode";
                description = "UPS '{{ $labels.model }}' is in bypass mode, meaning it's not actively protecting the load.";
              };
            }
            {
              alert = "UPSLoadHigh";
              expr = "network_ups_tools_ups_load > 80";
              for = "2m";
              labels.severity = "warning";
              annotations = {
                summary = "UPS load is high";
                description = "UPS '{{ $labels.model }}' is at {{ $value }}% load. Consider reducing the load or upgrading.";
              };
            }
            {
              alert = "UPSOutputVoltageHigh";
              expr = "network_ups_tools_output_voltage > 250";
              for = "2m";
              labels.severity = "warning";
              annotations = {
                summary = "UPS output voltage high";
                description = "UPS '{{ $labels.model }}' output voltage is at {{ $value }}V, which is higher than expected.";
              };
            }
            {
              alert = "UPSInputVoltageLow";
              expr = "network_ups_tools_input_voltage < 200";
              for = "2m";
              labels.severity = "warning";
              annotations = {
                summary = "UPS input voltage low";
                description = "UPS '{{ $labels.model }}' input voltage is at {{ $value }}V, which may indicate a power issue.";
              };
            }
          ];
        }
        {
          name = "ntoulapa";
          rules = [
            {
              alert = "HostRaidDiskFailure";
              expr = ''node_md_disks{state="failed"} > 0'';
              for = "2m";
              labels.severity = "warning";
              annotations = {
                summary = "Host RAID disk failure";
                description = "At least one device in RAID array failed. Array {{ $labels.md_device }} needs attention and possibly a disk swap";
              };
            }
            {
              alert = "HostRaidArrayGotInactive";
              expr = ''node_md_state{state="inactive"} > 0'';
              for = "0m";
              labels.severity = "critical";
              annotations = {
                summary = "Host RAID array got inactive";
                description = "RAID array {{ $labels.device }} is in degraded state due to one or more disks failures. Number of spare drives is insufficient to fix issue automatically";
              };
            }
            {
              alert = "HostUnusualDiskReadLatency";
              expr = ''rate(node_disk_read_time_seconds_total{instance!="sfiri"}[1m]) / rate(node_disk_reads_completed_total{instance!="sfiri"}[1m]) > 0.2 and rate(node_disk_reads_completed_total{instance!="sfiri"}[1m]) > 0'';
              for = "2m";
              labels.severity = "warning";
              annotations = {
                summary = "Host unusual disk read latency";
                description = "Disk latency is growing (read operations > 200ms): Currently at: {{ $value }} for {{ $labels.device }}";
              };
            }
            {
              alert = "HostUnusualDiskWriteLatency";
              expr = ''rate(node_disk_write_time_seconds_total{instance!="sfiri"}[1m]) / rate(node_disk_writes_completed_total{instance!="sfiri"}[1m]) > 0.2 and rate(node_disk_writes_completed_total{instance!="sfiri"}[1m]) > 0'';
              for = "2m";
              labels.severity = "warning";
              annotations = {
                summary = "Host unusual disk write latency";
                description = "Disk latency is growing (write operations > 200ms): Currently at: {{ $value }} for {{ $labels.device }}";
              };
            }
            {
              alert = "HostSystemdServiceCrashed";
              expr = ''node_systemd_unit_state{state="failed"} == 1'';
              for = "0m";
              labels.severity = "warning";
              annotations = {
                summary = "Host systemd service crashed";
                description = "systemd service {{ $labels.name }} crashed";
              };
            }
            {
              alert = "BackupHasErrors";
              expr = "restic_check_success != 1";
              for = "1m";
              labels.severity = "warning";
              annotations = {
                summary = "Backup failed";
                description = "restic check failed, refer to /var/log/restic_mon.log";
              };
            }
            {
              alert = "NoBackupLast48H";
              expr = "absent(restic_backup_timestamp) or ((time() - restic_backup_timestamp) / 3600) > 48";
              for = "1m";
              labels.severity = "warning";
              annotations = {
                summary = "There is no backup in the last 48hours";
                description = "Last backup was taken at {{ printf `restic_last_snapshot_ts` | query | first | value | humanizeTimestamp }}";
              };
            }
            {
              alert = "BackupDroppedInBytes";
              expr = "absent(restic_backup_size_total) or restic_backup_size_total OFFSET 1d - restic_backup_size_total > restic_backup_size_total OFFSET 1d * 0.1";
              for = "1m";
              labels.severity = "warning";
              annotations = {
                summary = "Backup in bytes dropped by 10%";
                description = "Current size is: {{ $value | humanize }}";
              };
            }
            {
              alert = "ZFSDegradedOrFailed";
              expr = ''node_zfs_zpool_state{state!="online"} == 1'';
              for = "1m";
              labels.severity = "critical";
              annotations = {
                summary = "ZFS Pool Issue Detected";
                description = "ZFS pool {{ $labels.zpool }} is in state {{ $labels.state }}. Run `zpool status` to investigate.";
              };
            }
            {
              alert = "ZFSNotMounted";
              expr = ''absent(node_filesystem_size_bytes{mountpoint="/zfs"})'';
              for = "10s";
              labels.severity = "warning";
              annotations = {
                summary = "ZFS is down";
                description = "ZFS is down";
              };
            }
            {
              alert = "OutOfDiskSpace";
              expr = ''(node_filesystem_avail_bytes{mountpoint="/"}  * 100) / node_filesystem_size_bytes{mountpoint="/"} < 10'';
              for = "5m";
              labels.severity = "warning";
              annotations = {
                summary = "Out of disk space (instance {{ $labels.instance }})";
                description = "Disk is almost full (< 10% left): Currently at: {{ $value }}";
              };
            }
            {
              alert = "DiskWillFillIn4Hours";
              expr = ''predict_linear(node_filesystem_free_bytes{fstype!~"tmpfs"}[1h], 4 * 3600) < 0'';
              for = "5m";
              labels.severity = "warning";
              annotations = {
                summary = "Disk will fill in 4 hours (instance {{ $labels.instance }})";
                description = "Disk will fill in 4 hours at current write rate";
              };
            }
            {
              alert = "PhysicalComponentTooHot";
              expr = "node_hwmon_temp_celsius > 75";
              for = "1m";
              labels.severity = "warning";
              annotations = {
                summary = "Physical component too hot (instance {{ $labels.instance }})";
                description = "Physical hardware component too hot. Currently at: {{ $value }}";
              };
            }
            {
              alert = "DomainExpiring";
              expr = "domain_expiry_days < 30";
              for = "1h";
              labels.severity = "warning";
              annotations = {
                description = "Domain {{ $labels.domain }} will expire in less than 30 days";
                summary = "{{ $labels.domain }}: domain is expiring";
              };
            }
            {
              alert = "HostConntrackLimit";
              expr = "node_nf_conntrack_entries / node_nf_conntrack_entries_limit > 0.8";
              for = "2m";
              labels.severity = "warning";
              annotations = {
                summary = "Host conntrack limit (instance {{ $labels.instance }})";
                description = "The number of conntrack is approaching limit\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
              };
            }
            {
              alert = "DiskReallocatedSectors";
              expr = "increase(smartmon_reallocated_sector_ct_raw_value[1m]) > 0";
              for = "0m";
              labels.severity = "info";
              annotations = {
                summary = "Disk reallocated sectors (instance {{ $labels.instance }})";
                description = "Reallocated sectors on disk\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
              };
            }
            {
              alert = "DiskCurrentPendingSector";
              expr = "smartmon_current_pending_sector_raw_value > 0";
              for = "0m";
              labels.severity = "warning";
              annotations = {
                summary = "Disk current pending sector (instance {{ $labels.instance }})";
                description = "Disk current pending sector\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
              };
            }
            {
              alert = "UncorrectableDiskSectors";
              expr = "increase(smartmon_offline_uncorrectable_raw_value[2m]) > 0";
              for = "0m";
              labels.severity = "warning";
              annotations = {
                summary = "Reported uncorrectable disk sectors (instance {{ $labels.instance }})";
                description = "Reported uncorrectable disk sectors\n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
              };
            }
            {
              alert = "SSDWearLevel";
              expr = "smartmon_wear_leveling_count_value < 30";
              for = "0m";
              labels.severity = "warning";
              annotations = {
                summary = "SSD's wear level is dangerously low, replace it (instance {{ $labels.instance }})";
                description = "SSD Wear level is low \n  VALUE = {{ $value }}\n  LABELS = {{ $labels }}";
              };
            }
          ];
        }
      ];
    }
  ))
]
