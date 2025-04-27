{ config, lib, pkgs, ... }:
let
  configure-gtk = pkgs.writeTextFile {
    name = "configure-gtk";
    destination = "/bin/configure-gtk";
    executable = true;
    text =
      let
        schema = pkgs.gsettings-desktop-schemas;
        datadir = "${schema}/share/gsettings-schemas/${schema.name}";
        gtk3_datadir = "${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}";
      in
      ''
        export XDG_DATA_DIRS=${datadir}:${gtk3_datadir}:$XDG_DATA_DIRS
        gnome_schema=org.gnome.desktop.interface
      '';
  };
  gnome-polkit-authentication-agent = pkgs.writeTextFile {
    name = "gnome-polkit-authentication-agent";
    destination = "/bin/gnome-polkit-authentication-agent";
    executable = true;

    text = ''
      ${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1
    '';
  };
in
{
  environment.systemPackages = with pkgs; [
    swaynotificationcenter
    libnotify
    swaylock
    xwayland
    swaybg
    swayidle
    swaylock
    configure-gtk
    polkit_gnome
    gnome-polkit-authentication-agent
    glib
    dbus
    rofi-wayland
    shikane
    arc-theme
    gtk3
    configure-gtk
    gsettings-desktop-schemas # Required for `gsettings` commands
    nautilus
    grim
    gucharmap
    slurp
    xorg.xev
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  services.gnome.gnome-keyring.enable = true;
  security.polkit.enable = true;

  services.gvfs.enable = true;
  programs.dconf.enable = true;
  services.dbus.implementation = "broker";

  services.libinput.enable = true;
  services.logind.killUserProcesses = true;
  services.logind.lidSwitch = "ignore";
  services.displayManager = {
    defaultSession = "sway";
  };
  programs.sway.package = pkgs.swayfx;

  services.displayManager.autoLogin = {
    enable = true;
    user = "lgian";
  };
  services.xserver.displayManager = {
    gdm.enable = true;
    gdm.wayland = true;
  };
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;
  programs.sway.enable = true;
  programs.sway.wrapperFeatures.gtk = true;

  fonts = {
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    packages = with pkgs; [
      corefonts # Microsoft free fonts
      dejavu_fonts
      dina-font
      noto-fonts
      noto-fonts-emoji
      nerdfonts
      powerline-fonts
      font-awesome_5
      font-awesome_4
      material-icons
      fira-code
      inconsolata
    ];
  };
}
