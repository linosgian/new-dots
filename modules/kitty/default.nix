{home-manager, config, pkgs, ...}:
{
  home.file = {
    ".config/kitty/pass_keys.py".source = ./pass_keys.py;
    ".config/kitty/get_layout.py".source = ./get_layout.py;
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
      "ctrl+f>c" = "new_tab";
      "ctrl+f>q" = "close_window";
      "ctrl+f>d" = "close_tab";
      "ctrl+f>," = "set_tab_title";
      "ctrl+f>z" = "next_layout";
      "ctrl+1" = "goto_tab 1";
      "ctrl+2" = "goto_tab 2";
      "ctrl+3" = "goto_tab 3";
      "ctrl+4" = "goto_tab 4";
      "ctrl+5" = "goto_tab 5";
      "ctrl+6" = "goto_tab 6";
      "ctrl+7" = "goto_tab 7";
      "ctrl+8" = "goto_tab 8";
      "ctrl+9" = "goto_tab 9";
      "ctrl+f>u" = "kitten hints";
      "ctrl+f>p" = "kitten hints --type path --program @";
      "ctrl+f>h" = "kitten hints --type hash --program @";
    };
    extraConfig = ''
      mouse_map ctrl+left press ungrabbed mouse_selection rectangle
    '';
  };
}
