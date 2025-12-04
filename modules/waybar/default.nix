{
  bigger-bar-screens,
  smaller-bar-screens,
  config,
  pkgs,
  ...
}:
let
  mainBar = rec {
    modules-left = [
      "sway/workspaces"
      "sway/mode"
      "sway/scratchpad"
      "custom/media"
    ];
    modules-center = [
      "clock"
    ];
    modules-right = [
      "pulseaudio"
      "network"
      "cpu"
      "memory"
      "temperature"
      "sway/language"
      "battery"
      "bluetooth"
      "tray"
    ];
    spacing = 4;

    # Bluetooth module settings
    bluetooth = {
      format = " {status}";
      format-connected = " {device_alias}";
      format-connected-battery = " {device_alias} {device_battery_percentage}% {icon}";
      format-icons = [
        ""
        ""
        ""
        ""
        ""
      ];
      tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
      tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
      tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
      tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
    };

    # Sway language module settings
    "sway/language" = {
      on-click = "swaymsg input type:keyboard xkb_switch_layout next";
      format = "{flag}";
    };

    # Sway workspaces module settings
    "sway/workspaces" = {
      disable-scroll = true;
      active-only = true;
      warp-on-scroll = false;
      format = "{name}: {icon}";
      format-icons = {
        "1" = " ";
        "2" = "";
        "3" = "";
        "4" = "";
        "5" = "";
        "6" = " ";
        "7" = " ";
        "8" = " ";
        "9" = " ";
        "10" = " ";
      };
    };

    # Sway mode module settings
    "sway/mode" = {
      format = "<span color='#ffead3' style=\"italic\">{}</span>";
    };

    # Sway scratchpad module settings
    "sway/scratchpad" = {
      format = "{icon} {count}";
      show-empty = false;
      format-icons = [
        ""
        ""
      ];
      tooltip = true;
      tooltip-format = "{app}: {title}";
    };

    # Idle inhibitor module settings
    idle_inhibitor = {
      format = "{icon}";
      format-icons = {
        activated = "";
        deactivated = "";
      };
    };

    # Tray module settings
    tray = {
      spacing = 10;
    };

    # Clock module settings
    clock = {
      format = " {:%a %b %e, %H:%M}";
      tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
      calendar = {
        mode = "year";
        mode-mon-col = 3;
        weeks-pos = "right";
        on-scroll = 1;
        format = {
          months = "<span color='#ffead3'><b>{}</b></span>";
          days = "<span color='#ecc6d9'><b>{}</b></span>";
          weeks = "<span color='#99ffdd'><b>W{}</b></span>";
          weekdays = "<span color='#ffcc66'><b>{}</b></span>";
          today = "<span color='#ff6699'><b><u>{}</u></b></span>";
        };
      };
      actions = {
        on-click-right = "mode";
        on-scroll-up = "tz_up";
        on-scroll-down = "tz_down";
      };
      format-alt = "{:%Y-%m-%d}";
    };

    # CPU module settings
    cpu = {
      format = "{usage:2}% ";
      tooltip = true;
      format-icons = [
        "▁"
        "▂"
        "▃"
        "▄"
        "▅"
        "▆"
        "▇"
        "█"
      ];
      interval = 5;
    };

    # Memory module settings
    memory = {
      format = "{used:1} GB ";
      interval = 2;
    };

    # Temperature module settings
    temperature = {
      interval = 2;
      thermal-zone = 11; # pkg temperature
      critical-threshold = 80;
      format = "{temperatureC}°C {icon}";
      format-icons = [
        ""
      ];
    };

    # Backlight module settings
    backlight = {
      format = "{percent}% {icon}";
      format-icons = [
        ""
        ""
        ""
        ""
        ""
        ""
        ""
        ""
        ""
      ];
    };

    # Battery module settings
    battery = {
      states = {
        warning = 25;
        critical = 15;
      };
      format = "{capacity}% {icon}";
      format-full = "{capacity}% {icon}";
      format-charging = "{capacity}% ";
      format-plugged = "{capacity}% ";
      format-alt = "{time} {icon}";
      format-icons = [
        ""
        ""
        ""
        ""
        ""
      ];
    };

    # Network module settings
    network = {
      format-wifi = "  {essid} ({signalStrength}%) | {bandwidthDownBits} /  {bandwidthUpBits}";
      format-ethernet = " {ipaddr}/{cidr} |  {bandwidthDownBits} /  {bandwidthUpBits}";
      tooltip-format = "{ifname} via {gwaddr} ";
      format-linked = "{ifname} (No IP) ";
      format-disconnected = "Disconnected ⚠";
      format-alt = "{ifname}: {ipaddr}/{cidr}";
      interval = 1;
    };

    # Pulseaudio module settings
    pulseaudio = {
      format = "{volume}% {icon} {format_source}";
      format-bluetooth = "{volume}% {icon} {format_source}";
      format-bluetooth-muted = " {icon} {format_source}";
      format-muted = " {format_source}";
      format-source = "{volume}% ";
      format-source-muted = "";
      format-icons = {
        headphone = "";
        hands-free = "";
        headset = "";
        phone = "";
        portable = "";
        car = "";
        default = [
          "󱣀"
          "󱣀"
          ""
        ];
      };
      on-click = "pavucontrol";
    };
  };
in
{
  programs.waybar = {
    enable = true;
    style = builtins.readFile ./style.css;
    settings = [
      (mainBar // { output = bigger-bar-screens; })
      (
        mainBar
        // {
          output = smaller-bar-screens;
          modules-right = builtins.filter (m: m != "bluetooth") mainBar.modules-right;
        }
      )
    ];
  };
}
