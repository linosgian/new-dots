{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.shikane;
  format = pkgs.formats.toml { };
in {
  options.services.shikane = {
    enable = mkEnableOption "shikane display configuration daemon";

    extraSystemdArgs = lib.mkOption {
      type = lib.types.str;
      default = "--skip-tests=true";
      example = "--skip-tests=true";
      description = ''
        foo
      '';

    };
    systemdTarget = lib.mkOption {
      type = lib.types.str;
      default = "sway-session.target";
      example = "sway-session.target";
      description = ''
        The systemd target that will automatically start the CopyQ service.

        When setting this value to `"sway-session.target"`,
        make sure to also enable {option}`wayland.windowManager.sway.systemd.enable`,
        otherwise the service may never be started.
      '';
    };

    package = mkOption {
      type = types.package;
      default = pkgs.shikane;
      defaultText = literalExpression "pkgs.shikane";
      description = "The shikane package to use.";
    };

    profiles = lib.mkOption {
      type = lib.types.listOf (lib.types.submodule {
        options = {
          name = lib.mkOption {
            type = lib.types.str;
          };
          output = lib.mkOption {
            type = lib.types.listOf lib.types.attrs;
          };
        };
      });
      default = [];
      description = "Display profiles configuration";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."shikane/config.toml" = {
      source = (pkgs.formats.toml {}).generate "shikane-config" { 
        profile = cfg.profiles;
      };
    };
    systemd.user.services.shikane = {
      Unit = {
        Description = "Shikane display configuration daemon";
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = "${cfg.package}/bin/shikane ${cfg.extraSystemdArgs}";
        Restart = "on-failure";
      };

      Install = { WantedBy = [ cfg.systemdTarget ]; };
    };
  };
}
