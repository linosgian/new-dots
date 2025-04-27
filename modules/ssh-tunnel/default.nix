{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.sshTunnel;
in
{
  options.services.sshTunnel = {
    enable = mkEnableOption "SSH tunnel service";

    # Add user configuration options
    user = mkOption {
      type = types.str;
      description = "User to run the SSH tunnel services";
      default = "root";
      example = "myuser";
    };

    group = mkOption {
      type = types.str;
      description = "Group to run the SSH tunnel services";
      default = "root";
      example = "mygroup";
    };

    tunnels = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          enable = mkEnableOption "this specific SSH tunnel" // {
            default = true;
          };

          localPort = mkOption {
            type = types.port;
            description = "Local port to forward to";
            example = 8500;
          };

          remoteHost = mkOption {
            type = types.str;
            description = "SSH server to connect to";
            example = "bastion-host.example.com";
          };

          remoteUser = mkOption {
            type = types.str;
            description = "SSH username for the remote host";
            example = "user";
            default = "root";
          };

          remotePort = mkOption {
            type = types.port;
            description = "SSH port on the remote host";
            example = 22;
            default = 22;
          };

          targetHost = mkOption {
            type = types.str;
            description = "Target host to forward to (as accessible from the SSH server)";
            example = "internal-service.local";
          };

          targetPort = mkOption {
            type = types.port;
            description = "Target port to forward to";
            example = 8500;
          };

          identityFile = mkOption {
            type = types.nullOr types.path;
            description = "Path to private key file for SSH authentication";
            example = "/home/user/.ssh/id_rsa";
            default = null;
          };

          extraSSHOptions = mkOption {
            type = types.listOf types.str;
            description = "Additional SSH options";
            default = [
              "StrictHostKeyChecking=accept-new"
              "ServerAliveInterval=60"
              "ExitOnForwardFailure=yes"
            ];
          };

          bindAddress = mkOption {
            type = types.str;
            description = "Local address to bind to";
            default = "127.0.0.1";
          };
        };
      });
      default = { };
      description = "Set of SSH tunnels to create";
      example = literalExpression ''
        {
          consul = {
            localPort = 8500;
            remoteHost = "bastion.example.com";
            remoteUser = "tunnel";
            targetHost = "consul-server.internal";
            targetPort = 8500;
            identityFile = "/root/.ssh/tunnel_key";
          };
        }
      '';
    };
  };

  config = mkIf cfg.enable {
    # Create the SSH tunnel services
    systemd.services = mapAttrs'
      (name: tunnelCfg:
        nameValuePair "ssh-tunnel-${name}" (mkIf tunnelCfg.enable {
          description = "SSH tunnel for ${name} (${tunnelCfg.targetHost}:${toString tunnelCfg.targetPort})";

          wantedBy = [ "multi-user.target" ];
          after = [ "network.target" ];

          # Script to verify port availability before starting the tunnel
          preStart = ''
            ${pkgs.nettools}/bin/nc -z ${tunnelCfg.bindAddress} ${toString tunnelCfg.localPort} && {
              echo "Error: Port ${toString tunnelCfg.localPort} is already in use"
              exit 1
            } || {
              echo "Port ${toString tunnelCfg.localPort} is available"
            }
          '';

          serviceConfig = {
            Type = "simple";
            Restart = "on-failure";
            RestartSec = "10s";

            # Run as the specified user instead of DynamicUser
            User = cfg.user;
            Group = cfg.group;

            # Build the SSH command
            ExecStart =
              let
                identityFlag =
                  if tunnelCfg.identityFile != null
                  then "-i ${tunnelCfg.identityFile}"
                  else "";

                sshOptions = concatStringsSep " "
                  (map (opt: "-o ${opt}") tunnelCfg.extraSSHOptions);
              in
              ''
                ${pkgs.openssh}/bin/ssh \
                  -L ${tunnelCfg.bindAddress}:${toString tunnelCfg.localPort}:${tunnelCfg.targetHost}:${toString tunnelCfg.targetPort} \
                  ${tunnelCfg.remoteUser}@${tunnelCfg.remoteHost} \
                  -p ${toString tunnelCfg.remotePort} \
                  ${identityFlag} \
                  ${sshOptions} \
                  -N
              '';

            # Limit service permissions but keep access to SSH keys
            PrivateTmp = true;
            ProtectSystem = "strict";
            ReadWritePaths = mkIf (tunnelCfg.identityFile != null) [
              # Allow access to the directory containing the SSH key
              (dirOf tunnelCfg.identityFile)
            ];

            # SSH will maintain its own connection
            KillMode = "process";
          };
        })
      )
      cfg.tunnels;
  };
}
