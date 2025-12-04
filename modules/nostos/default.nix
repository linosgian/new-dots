{
  config,
  pkgs,
  lib,
  ...
}:

let
  nostos = pkgs.callPackage ../../pkgs/nostos { };
in
{
  environment.systemPackages = [ nostos ];
  # The instance name will be in format: duration-outputname
  # Example: nostos@2h-morning.service
  systemd.services."nostos@" = {
    description = "Nostos Recording Service - %i";
    after = [ "network.target" ];

    serviceConfig = {
      Type = "simple";
      User = "nostos";
      Group = "nostos";

      # Use ExecStart with a wrapper script
      ExecStart =
        let
          wrapper = pkgs.writeShellScript "nostos-wrapper" ''
            # Instance name format: duration-outputname
            # Example: 2h-morning or 3h30m-evening
            INSTANCE="$1"

            # Split on the first dash
            DURATION=$(echo "$INSTANCE" | cut -d'-' -f1)
            OUTPUT_NAME=$(echo "$INSTANCE" | cut -d'-' -f2-)

            # Set environment variables
            export STREAM_URL="''${STREAM_URL:-https://rdst.win:48051/}"
            export OUTPUT_PATH="/var/lib/nostos/$OUTPUT_NAME"
            export RECORDING_DURATION="$DURATION"

            # Create output directory if it doesn't exist
            mkdir -p "$OUTPUT_PATH"

            # Run the nostos binary
            exec ${nostos}/bin/nostos
          '';
        in
        "${wrapper} %i";

      # Allow writing to /var/lib/nostos
      ProtectSystem = "strict";
      ReadWritePaths = [
        "/var/lib/nostos"
        "/tmp"
      ];

      # Security hardening
      ProtectHome = true;
      NoNewPrivileges = true;
    };
  };

  # Format: nostos@<duration>-<output_name>.timer
  systemd.timers."nostos@3h-earlybirds" = {
    description = "Timer for Nostos - Early birds (3h)";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Mon-Fri *-*-* 08:00:00";
      Persistent = false;
    };
  };

  systemd.timers."nostos@2h-kourafelkithra" = {
    description = "Timer for Nostos - Kourafelkithra (2h)";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sat *-*-* 11:00:00";
      Persistent = false;
    };
  };

  # Create the user
  users.users.nostos = {
    isSystemUser = true;
    group = "nostos";
    description = "User for nostos service";
  };

  users.groups.nostos = { };
}
