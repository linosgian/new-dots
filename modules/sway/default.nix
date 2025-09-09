{
  home-manager,
  config,
  pkgs,
  ...
}:
let
  wallpaperPath = ".config/sway/wallpaper.jpg";
  wallpaperAbsPath = "${config.home.homeDirectory}/${wallpaperPath}";
in
{
  home.file."${wallpaperPath}".source = ./wallpaper.jpg;

  home.packages = with pkgs; [
    rofi-power-menu
  ];

  services.blueman-applet = {
    enable = true;
  };

  services.network-manager-applet = {
    enable = true;
  };

  programs.swaylock = {
    enable = true;
    settings = {
      daemonize = true;
      font-size = 15;
      indicator-radius = 100;
      indicator-thickness = 15;
      line-uses-ring = true;
      image = "${wallpaperAbsPath}";
      ignore-empty-password = true;
    };
  };

  wayland.windowManager.sway = {
    enable = true;
    package = pkgs.swayfx;

    checkConfig = false;
    config = {
      modifier = "Mod1";
      floating.modifier = "Mod1";
      workspaceLayout = "stacking";

      keybindings = {
        "Mod1+r" = "exec --no-startup-id rofi -show power-menu -modi power-menu:rofi-power-menu";

        # Application Launchers
        "Mod1+Return" =
          "exec kitty -o allow_remote_control=yes --single-instance --listen-on unix:@mykitty";
        "Mod1+d" =
          "exec --no-startup-id rofi -auto-select -dpi 120 -sorting-method fzf -sort -matching fuzzy -modi drun -show drun -show-icons -drun-match-fields name";
        "Mod1+o" = "exec --no-startup-id bash switcher.sh";

        # Screenshots
        "Insert" = "exec bash screenshot.sh";
        "Control+Insert" = "exec bash screenshot.sh --screen";

        # Window Management
        "Mod1+q" = "kill";
        "Mod1+h" = "focus left";
        "Mod1+j" = "focus down";
        "Mod1+k" = "focus up";
        "Mod1+l" = "focus right";
        "Mod1+Shift+h" = "move left";
        "Mod1+Shift+j" = "move down";
        "Mod1+Shift+k" = "move up";
        "Mod1+Shift+l" = "move right";
        "Mod1+f" = "fullscreen toggle";
        "Mod1+Shift+space" = "floating toggle";
        "Mod1+space" = "focus mode_toggle";

        # Layouts
        "Mod1+s" = "layout stacking";
        "Mod1+w" = "layout tabbed";
        "Mod1+e" = "layout toggle split";
        "Mod1+v" = "split toggle";
        "Mod1+u" = "exec bash scratch.sh";

        # Workspaces
        "Mod1+1" = "workspace 1";
        "Mod1+2" = "workspace 2";
        "Mod1+3" = "workspace 3";
        "Mod1+4" = "workspace 4";
        "Mod1+5" = "workspace 5";
        "Mod1+6" = "workspace 6";
        "Mod1+7" = "workspace 7";
        "Mod1+8" = "workspace 8";
        "Mod1+9" = "workspace 9";
        "Mod1+0" = "workspace 10";

        "Mod1+Shift+1" = "move container to workspace 1";
        "Mod1+Shift+2" = "move container to workspace 2";
        "Mod1+Shift+3" = "move container to workspace 3";
        "Mod1+Shift+4" = "move container to workspace 4";
        "Mod1+Shift+5" = "move container to workspace 5";
        "Mod1+Shift+6" = "move container to workspace 6";
        "Mod1+Shift+7" = "move container to workspace 7";
        "Mod1+Shift+8" = "move container to workspace 8";
        "Mod1+Shift+9" = "move container to workspace 9";
        "Mod1+Shift+0" = "move container to workspace 10";

        # Reload Configuration
        "Mod1+Shift+r" = "exec swaymsg reload";

        # Notifications
        "ctrl+space" = "exec --no-startup-id swaync-client --close-latest";
        "ctrl+Shift+space" = "exec --no-startup-id swaync-client -C";

        # Volume and Brightness
        "XF86AudioRaiseVolume" = "exec --no-startup-id bash volcontrol.sh up";
        "XF86AudioLowerVolume" = "exec --no-startup-id bash volcontrol.sh down";
        "XF86AudioMute" = "exec --no-startup-id bash volcontrol.sh mute";
        "XF86MonBrightnessUp" = "exec brightnessctl set +5%";
        "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
      };

      input = {
        "*" = {
          xkb_layout = "us,gr";
          xkb_options = "grp:win_space_toggle";
        };
      };

      ## TODO: make those configurable
      workspaceOutputAssign = [
        {
          output = "DP-4";
          workspace = "1";
        }
        {
          output = "DP-4";
          workspace = "2";
        }
        {
          output = "DP-3";
          workspace = "3";
        }
        {
          output = "DP-4";
          workspace = "4";
        }
        {
          output = "DP-3";
          workspace = "5";
        }
        {
          output = "DP-4";
          workspace = "6";
        }
        {
          output = "DP-4";
          workspace = "7";
        }
        {
          output = "DP-4";
          workspace = "8";
        }
        {
          output = "DP-4";
          workspace = "9";
        }
      ];

      assigns = {
        "4" = [ { app_id = "slack"; } ];
        "3" = [ { app_id = "spotify"; } ];
        "5" = [ { app_id = "evince"; } ];
      };
      window.commands = [
        {
          criteria = {
            app_id = "slack";
          };
          command = "assign 4";
        }
        {
          criteria = {
            app_id = "evince";
          };
          command = "assign 5";
        }
        {
          criteria = {
            app_id = "scratchpad";
          };
          command = "floating enable";
        }
        {
          criteria = {
            app_id = "scratchpad";
          };
          command = "move scratchpad";
        }
        {
          criteria = {
            app_id = "scratchpad";
          };
          command = "move position center";
        }
        {
          criteria = {
            app_id = "scratchpad";
          };
          command = "resize set 50 50";
        }
        {
          criteria = {
            app_id = "scratchpad";
          };
          command = "border pixel 2";
        }
        {
          criteria = {
            app_id = "scratchpad";
          };
          command = "sticky enable";
        }
        {
          criteria = {
            app_id = "pavucontrol";
          };
          command = "floating enable, border normal";
        }
        {
          criteria = {
            app_id = "pavucontrol";
          };
          command = "resize set 1200 800";
        }
      ];
      startup = [
        {
          command = "swaymsg 'exec kitty --class=\"scratchpad\" -o allow_remote_control=yes --listen-on unix:/tmp/mykitty1'";
          always = false;
        }
        {
          command = "swaymsg -t get_inputs | jq -r '.[] | select(.type==\"touchpad\") | .identifier' | xargs -i swaymsg input \"{}\" natural_scroll enabled";
          always = true;
        }
        {
          command = "swaymsg -t get_inputs | jq -r '.[] | select(.type==\"touchpad\") | .identifier' | xargs -i swaymsg input \"{}\" tap enabled";
          always = true;
        }
        {
          command = "swaymsg 'workspace 1; exec kitty -o allow_remote_control=yes --listen-on unix:/tmp/mykitty3'";
          always = false;
        }
        {
          command = "systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP WLR_NO_HARDWARE_CURSORS";
          always = false;
        }
        {
          command = "systemctl --user start libinput-gestures.service";
          always = false;
        }
        {
          command = "gnome-polkit-authentication-agent";
          always = true;
        }
        {
          command = "swaybg -i ${wallpaperAbsPath} -m fill";
          always = true;
        }
        {
          command = "source configure-gtk";
          always = true;
        }
        {
          command = "gsettings set org.gnome.desktop.interface  gtk-theme 'Arc-Dark'";
          always = true;
        }
        {
          command = "systemctl --user restart kanshi";
          always = true;
        }

      ];

      bars = [
        {
          command = "waybar";
        }
      ];
    };
    extraConfig = ''
      seat * xcursor_theme WhiteSur-cursors 32
      blur true
      blur_radius 5
      blur_saturation 2
      shadows enbale
      corner_radius 20
      shadow_blur_radius 5
      shadow_offset 0 1
      layer_effects "gtk-layer-shell" {
          blur enable
          corner_radius 20
      }
    '';
  };
}
