{home-manager, config, pkgs, ...}:
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
      thermal-zone = 6; # pkg temperature
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
      format-wifi = "  {essid} ({signalStrength}%) |  {bandwidthDownBits} /  {bandwidthUpBits}";
      format-ethernet = " {ipaddr}/{cidr} |  {bandwidthDownBits} /  {bandwidthUpBits}";
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
          ""
          ""
          ""
        ];
      };
      on-click = "pavucontrol";
    };

    # Custom media module settings
    "custom/media" = {
      format = "{0} {2}";
      return-type = "json";
      max-length = 100;
      format-icons = {
        spotify = " ";
        default = "🎜 ";
      };
      exec = "waybar-mediaplayer.py 2> /dev/null";
    };
  };
in
{
  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;

  nixpkgs.overlays = [
    (self: super: {
      waybar = super.waybar.override {
        withMediaPlayer = true;
      };
    })
  ];

  home-manager.users.lgian = { lib, ...}:{
    home.stateVersion = "24.11";
    home.packages = with pkgs; [
      (pkgs.writeShellScriptBin "kube_ps1.sh" (builtins.readFile ./zsh/kube_ps1.sh))
      (import ./pkgs/sway-scripts { inherit pkgs; })
      fzf
      ripgrep
      evince
    ];

    services.ssh-agent = {
      enable = true;
    };

    # ZSH / FZF
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
    };

    programs.zsh = {
      enable = true;
      enableCompletion = false;
      autosuggestion.enable = true;
      autocd = true;
      dotDir = ".config/zsh";
      history = {
        path = "/home/lgian/.zsh_history";
        size = 10000000;
        save = 10000000;
        ignoreAllDups = true;
        ignoreSpace = true;
        share = true;
      };
      initExtra = builtins.readFile ./zsh/initextra.zsh;
    };
    # Shikane 
    imports = [
      ./shikane.nix
    ];
    services.shikane = {
      enable = true;
      profiles = [
        {
          name = "Default";
          output = [{
            search = ["m=0x573D" "s=" "v=AU Optronics"];
            enable = true;
            mode = "1920x1080@60.033Hz";
            position = "0,0";
          }];
        }
        {
          name = "docked";
          output = [
            {
              enable = false;
              search = ["m=0x573D" "s=" "v=AU Optronics"];
            }
            {
              enable = true;
              search = ["m=DELL S2721DGF" "s=CTPGZ83" "v=Dell Inc."];
              mode = "2560x1440@59.951Hz";
              position = "0,0";
              scale = 1.0;
              transform = "normal";
              adaptive_sync = false;
            }
            {
              enable = true;
              search = ["m=BenQ EL2870U" "s=W4M06094SL0" "v=BNQ"];
              mode = "2560x1440@59.951Hz";
              position = "2560,0";
              scale = 1.0;
              transform = "normal";
              adaptive_sync = false;
            }
          ];
        }
      ];
    };

    # Kitty
    home.file = {
      ".config/kitty/pass_keys.py".source = ./kitty/pass_keys.py;
      ".config/kitty/get_layout.py".source = ./kitty/get_layout.py;
    };
    programs.kitty = {
      enable = true;
      font = {
        name = "Fira Code";
        size = 10.0;
      };
      settings = {
        foreground = "#ffffff";
        background = "#2e2e2e";
        cursor_shape = "block";
        cursor_text_color = "#111111";
        open_url_modifiers = "ctrl";
        confirm_os_window_close = "1";
        focus_follows_mouse = "yes";
        url_color = "#0087bd";
        url_style = "single";
        tab_bar_style = "powerline";
        tab_title_template = "{index} {title}";
        active_tab_title_template = "{index} {title} {'[Z]' if layout_name=='stack' else ''}";
        tab_bar_min_tabs = "1";
        active_border_color = "none";

        visual_bell_duration = "0.15";
        visual_bell_color = "#000000";
        active_tab_foreground = "#fff";
        active_tab_background = "#353";
        inactive_tab_foreground = "#fff";
        inactive_tab_background = "#666";
        inactive_tab_font_style = "normal";
        active_tab_font_style = "italic";
        inactive_border_color = "#508550";
        window_border_width = "0.1";
        window_margin_width = "0";
        window_padding_width = "0";
        scrollback_lines = "20000";
        copy_on_select = "yes";
        inactive_text_alpha = "0.7";
        enable_audio_bell = "no";
        # bell_path = "${pkgs.sound-theme-freedesktop}/share/sounds/freedesktop/stereo/dialog-warning.oga";
        enabled_layouts = "splits,stack";
        input_delay = "0";
        repaint_delay = "2";
        allow_remote_control = "yes";
        editor = "vim";
      };
      keybindings = {
        "ctrl+f>ctrl+f" = "previous_tab";
        "ctrl+shift+plus" = "change_font_size all +1.0";
        "ctrl+shift+minus" = "change_font_size all -1.0";
        "ctrl+shift+0" = "change_font_size all 0";
        "ctrl+f>r" = "start_resizing_window";
        "ctrl+f>/" = "show_scrollback";
        "ctrl+j" = "kitten pass_keys.py bottom ctrl+j";
        "ctrl+k" = "kitten pass_keys.py top ctrl+k";
        "ctrl+h" = "kitten pass_keys.py left ctrl+h";
        "ctrl+l" = "kitten pass_keys.py right ctrl+l";
        "ctrl+f>v" = "launch --cwd=current --location=vsplit";
        "ctrl+f>s" = "launch --cwd=current --location=hsplit";
        "ctrl+f>c" = "combine : new_tab : set_tab_title";
        "ctrl+f>q" = "close_window";
        "ctrl+f>d" = "close_tab";
        "ctrl+f>," = "set_tab_title";
        "ctrl+f>z" = "next_layout";
        "ctrl+f>1" = "goto_tab 1";
        "ctrl+f>2" = "goto_tab 2";
        "ctrl+f>3" = "goto_tab 3";
        "ctrl+f>4" = "goto_tab 4";
        "ctrl+f>5" = "goto_tab 5";
        "ctrl+f>6" = "goto_tab 6";
        "ctrl+f>7" = "goto_tab 7";
        "ctrl+f>8" = "goto_tab 8";
        "ctrl+f>9" = "goto_tab 9";
        "ctrl+f>u" = "kitten hints";
        "ctrl+f>p" = "kitten hints --type path --program @";
        "ctrl+f>h" = "kitten hints --type hash --program @";
      };
      extraConfig = ''
        mouse_map ctrl+left press ungrabbed mouse_selection rectangle
      '';
    };

    wayland.windowManager.sway = {
      enable = true;
      package = pkgs.swayfx;

      checkConfig = false;
      config = {
        modifier = "Mod1";
        floating.modifier = "Mod1";
        workspaceLayout = "stacking";

        modes = {
          "System  (l) lock, (d) suspend, (h) hibernate, (r) reboot, (s) shutdown" = {
            "l" = "exec --no-startup-id swaylock, mode default";
            "d" = "exec --no-startup-id exit.sh suspend, mode default";
            "h" = "exec --no-startup-id exit.sh hibernate, mode default";
            "r" = "exec --no-startup-id exit.sh reboot, mode default";
            "s" = "exec --no-startup-id exit.sh shutdown, mode default";
            "Return" = "mode default";
            "Escape" = "mode default";
          };
        };
        keybindings = {
          "Mod1+r" = "mode \"System  (l) lock, (d) suspend, (h) hibernate, (r) reboot, (s) shutdown\"";

          # Application Launchers
          "Mod1+Return" = "exec kitty -o allow_remote_control=yes --single-instance --listen-on unix:@mykitty";
          "Mod1+d" = "exec --no-startup-id rofi -auto-select -dpi 120 -sorting-method fzf -sort -matching fuzzy -modi drun -show drun -show-icons -drun-match-fields name";
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
          "4" = [{class = "Slack";}];
          "3" = [{class = "Spotify";}];
          "5" = [{app_id = "evince";}];
        };
        window.commands = [
          { criteria = { class = "Slack"; }; command = "assign 4"; }
          { criteria = { app_id = "evince"; }; command = "assign 5"; }
          { criteria = { app_id = "scratchpad"; }; command = "floating enable"; }
          { criteria = { app_id = "scratchpad"; }; command = "move scratchpad"; }
          { criteria = { app_id = "scratchpad"; }; command = "move position center"; }
          { criteria = { app_id = "scratchpad"; }; command = "resize set 50 50"; }
          { criteria = { app_id = "scratchpad"; }; command = "border pixel 2"; }
          { criteria = { app_id = "scratchpad"; }; command = "sticky enable"; }
          { criteria = { app_id = "pavucontrol"; }; command = "floating enable, border normal"; }
          { criteria = { app_id = "pavucontrol"; }; command = "resize set 1200 800"; }
        ];
        startup = [
          { command = "swaymsg 'exec kitty --class=\"scratchpad\" -o allow_remote_control=yes --listen-on unix:/tmp/mykitty1'"; always = false; }
          { command = "swaymsg -t get_inputs | jq -r '.[] | select(.type==\"touchpad\") | .identifier' | xargs -i swaymsg input \"{}\" natural_scroll enabled"; always = true; }
          { command = "swaymsg -t get_inputs | jq -r '.[] | select(.type==\"touchpad\") | .identifier' | xargs -i swaymsg input \"{}\" tap enabled"; always = true; }
          { command = "slack"; always = false; }
          { command = "swaymsg 'workspace 1; exec kitty -o allow_remote_control=yes --listen-on unix:/tmp/mykitty3'"; always = false; }
          { command = "systemctl --user import-environment DISPLAY WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP"; always = false; }
          { command = "systemctl --user start libinput-gestures.service"; always = false; }
          { command = "gnome-polkit-authentication-agent"; always = true; }
          { command = "swaybg -i $HOME/.config/sway/wallpaper.jpg -m fill"; always = true; }
          { command = "source configure-gtk"; always = true; }
          { command = "gsettings set org.gnome.desktop.interface  gtk-theme 'Arc-Dark'"; always = true; }
        ];

        bars = [
          {
            command = "waybar";
          }
        ];
      };
      extraConfig = ''
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

    services.blueman-applet = {
      enable = true;
    };
    services.network-manager-applet = {
      enable = true;
    };
    services.swaync = {
      enable = true;
      style = builtins.readFile ./swaync/style.css;
      settings = {
        positionX = "right";
        positionY = "top";
        control-center-margin-top = 10;
        control-center-margin-bottom = 0;
        control-center-margin-right = 10;
        control-center-margin-left = 0;
        notification-icon-size = 64;
        notification-body-image-height = 100;
        notification-body-image-width = 200;
        timeout = 10;
        timeout-low = 5;
        timeout-critical = 0;
        fit-to-screen = false;
        control-center-width = 500;
        control-center-height = 600;
        notification-window-width = 500;
        keyboard-shortcuts = true;
        image-visibility = "when-available";
        transition-time = 200;
        hide-on-clear = false;
        hide-on-action = true;
        script-fail-notify = true;

        notification-visibility = {
          "example-name" = {
            state = "muted";
            urgency = "Low";
            app-name = "Spotify";
          };
        };

        widgets = [
          "menubar#label"
          "buttons-grid"
          "volume"
          "mpris"
          "title"
          "dnd"
          "notifications"
        ];

        widget-config = {
          title = {
            text = "Notifications";
            clear-all-button = true;
            button-text = "Clear All";
          };
          dnd = {
            text = "Do Not Disturb";
          };
          label = {
            max-lines = 1;
            text = "Control Center";
          };
          mpris = {
            image-size = 96;
            image-radius = 12;
          };
          volume = {
            label = "";
          };
        };
      };
    };
    home.file.".config/sway/wallpaper.jpg".source = ./sway/wallpaper.jpg;
    programs.swaylock = {
      enable = true;
      settings = {
        daemonize = true;
        font-size = 15;
        indicator-radius = 100;
        indicator-thickness = 15;
        line-uses-ring = true;
        image = "/home/lgian/.config/sway/wallpaper.jpg";
        ignore-empty-password = true;
      };
    };
    home.file.".config/git/gitconfig-work".text = ''
      [user]
        name = Linos Giannopoulos
        email = linos@contextflow.com
        signingkey = /home/lgian/.ssh/id_ed25519.pub

      [core]
        sshCommand = "ssh -i ~/.ssh/id_ed25519.pub"
    '';
    programs.git = {
      enable = true;
      userName = "Linos Giannopoulos";
      userEmail = "linosgian00@gmail.com";
      signing = {
        key = "/home/lgian/.ssh/old.pub";
        signByDefault = true;
      };

      aliases = {
        cmv = "commit -v";
        cma = "commit --amend -v";
        lg = ''log --graph --pretty=format:"%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit'';
        lgg = ''log --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset by %C(yellow)%ae%Creset' --abbrev-commit --date=relative'';
        amen = "!git add -A && git commit --amend --no-edit";
        st = "status -sb";
        dfc = "diff --cached";
        co = "checkout";
        cb = "checkout -b";
        br = "branch";
        f = "fetch";
        rbm = "pull --rebase origin master";
        rbc = "rebase --continue";
        rbs = "rebase --skip";
        rba = "rebase --abort";
        brr = ''for-each-ref --sort=committerdate refs/heads/ --format="%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))"'';
      };

      includes = [
        {
          condition = "gitdir:~/cflow/";
          path = "~/.config/.git/gitconfig-work";
        }
      ];

      extraConfig = {
        push = {
          default = "current";
          autoSetupRemote = true;
        };
        init.defaultBranch = "main";
        gpg.format = "ssh";
      };
    };
    programs.rofi = {
      enable = true;
      theme = let 
        inherit (config.home-manager.users.lgian.lib.formats.rasi) mkLiteral;
      in {
        "*" = {
          font = mkLiteral "\"Montserrat 12\"";
          bg0 = mkLiteral "#F5F5F5BF";
          bg1 = mkLiteral "#7E7E7E80";
          bg2 = mkLiteral "#0860F2E6";
          fg0 = mkLiteral "#242424";
          fg1 = mkLiteral "#FFFFFF";
          fg2 = mkLiteral "#24242480";
          background-color = mkLiteral "transparent";
          text-color = mkLiteral "@fg0";
          margin = 0;
          padding = 0;
          spacing = 0;
        };

        "window" = {
          background-color = mkLiteral "@bg0";
          location = mkLiteral "center";
          width = 640;
          border-radius = 8;
        };

        "inputbar" = {
          font = mkLiteral "\"Montserrat 20\"";
          padding = 12;
          spacing = 12;
          children = mkLiteral "[ icon-search, entry ]";
        };

        "icon-search" = {
          expand = false;
          filename = mkLiteral "\"search\"";
          size = mkLiteral "28px";
        };

        "icon-search, entry, element-icon, element-text" = {
          vertical-align = mkLiteral "0.5";
        };

        "entry" = {
          font = mkLiteral "inherit";
          placeholder = mkLiteral "\"Search\"";
          placeholder-color = mkLiteral "@fg2";
        };

        "message" = {
          border = mkLiteral "2px 0 0";
          border-color = mkLiteral "@bg1";
          background-color = mkLiteral "@bg1";
        };

        "textbox" = {
          padding = mkLiteral "8px 24px";
        };

        "listview" = {
          lines = 10;
          columns = 1;
          fixed-height = false;
          border = mkLiteral "1px 0 0";
          border-color = mkLiteral "@bg1";
        };

        "element" = {
          padding = mkLiteral "8px 16px";
          spacing = mkLiteral "16px";
          background-color = mkLiteral "transparent";
        };

        "element normal active" = {
          text-color = mkLiteral "@bg2";
        };

        "element alternate active" = {
          text-color = mkLiteral "@bg2";
        };

        "element selected normal, element selected active" = {
          background-color = mkLiteral "@bg2";
          text-color = mkLiteral "@fg1";
        };

        "element-icon" = {
          size = mkLiteral "1em";
        };

        "element-text" = {
          text-color = mkLiteral "inherit";
        };

      };
    };
    programs.waybar = {
      package = pkgs.waybar;
      enable = true;
      style = builtins.readFile ./waybar/style.css;
      settings = [
        # TODO: Add screens
        (mainBar // { output = [ "HDMI-1" ]; })
        (mainBar // {
          output = [ "eDP-1" ];
          modules-right = builtins.filter (m: m != "bluetooth") mainBar.modules-right;
        })
      ];
    };
  };
}
